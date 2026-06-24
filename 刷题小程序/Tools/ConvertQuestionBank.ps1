param(
    [string]$SourceDocx = "",
    [string]$OutputJson = "$PSScriptRoot\..\QuizPractice\Resources\questions.json",
    [string]$ReportPath = "$PSScriptRoot\..\QuestionBankReport.md"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Xml.Linq

function ConvertFrom-CodePoints {
    param([int[]]$CodePoints)

    $chars = $CodePoints | ForEach-Object { [char]$_ }
    return -join $chars
}

$MarkerReference = ConvertFrom-CodePoints @(0x53C2, 0x8003, 0x7B54, 0x6848)
$TextTrue = ConvertFrom-CodePoints @(0x5BF9)
$TextFalse = ConvertFrom-CodePoints @(0x9519)
$FullWidthDot = ConvertFrom-CodePoints @(0xFF0E)
$FullWidthComma = ConvertFrom-CodePoints @(0xFF0C)
$BankTitle = ConvertFrom-CodePoints @(0x9884, 0x9632, 0x63A5, 0x79CD, 0x4E13, 0x9879, 0x9898, 0x5E93)
$BankDescription = ConvertFrom-CodePoints @(0x542B, 0x5355, 0x9009, 0x3001, 0x591A, 0x9009, 0x3001, 0x5224, 0x65AD, 0xFF1B, 0x6BCF, 0x6B21, 0x7EC3, 0x4E60, 0x968F, 0x673A, 0x62BD, 0x53D6, 0x0031, 0x0035, 0x0030, 0x9898)

function Get-DocxParagraphs {
    param([string]$Path)

    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $zip.GetEntry("word/document.xml")
        if ($null -eq $entry) {
            throw "word/document.xml was not found in the DOCX file."
        }

        $stream = $entry.Open()
        try {
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
            $xmlText = $reader.ReadToEnd()
            $reader.Close()
        } finally {
            $stream.Close()
        }
    } finally {
        $zip.Dispose()
    }

    $doc = [System.Xml.Linq.XDocument]::Parse($xmlText)
    $w = [System.Xml.Linq.XNamespace]"http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    $paragraphs = New-Object System.Collections.Generic.List[string]

    foreach ($p in $doc.Descendants($w + "p")) {
        $sb = [System.Text.StringBuilder]::new()
        foreach ($node in $p.Descendants()) {
            if ($node.Name -eq ($w + "t")) {
                [void]$sb.Append($node.Value)
            } elseif ($node.Name -eq ($w + "tab") -or $node.Name -eq ($w + "br")) {
                [void]$sb.Append(" ")
            }
        }

        $text = [regex]::Replace($sb.ToString(), "\s+", " ").Trim()
        if ($text.Length -gt 0) {
            $paragraphs.Add($text)
        }
    }

    return $paragraphs
}

function Parse-AnswerMap {
    param([string[]]$Lines)

    $map = @{}
    $text = $Lines -join " "
    $dotPattern = "\." + [regex]::Escape($FullWidthDot)
    $pattern = "(\d+)[" + $dotPattern + "]([A-E]+|" + [regex]::Escape($TextTrue) + "|" + [regex]::Escape($TextFalse) + ")"
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $map[[int]$match.Groups[1].Value] = $match.Groups[2].Value
    }

    return $map
}

function Extract-Options {
    param([string]$Body)

    $separatorPattern = "\." + [regex]::Escape($FullWidthDot) + "," + [regex]::Escape($FullWidthComma)
    $matches = [regex]::Matches($Body, "(?<![A-Za-z0-9])([A-E])[" + $separatorPattern + "]")
    $markers = @()
    foreach ($match in $matches) {
        if ($match.Index -gt 0) {
            $markers += $match
        }
    }

    if ($markers.Count -lt 2) {
        return $null
    }

    $options = @()
    for ($i = 0; $i -lt $markers.Count; $i++) {
        $start = $markers[$i].Index + $markers[$i].Length
        $end = if ($i + 1 -lt $markers.Count) { $markers[$i + 1].Index } else { $Body.Length }
        $key = $markers[$i].Groups[1].Value
        $text = $Body.Substring($start, $end - $start).Trim()
        $options += [ordered]@{
            key = $key
            text = $text
        }
    }

    $questionText = $Body.Substring(0, $markers[0].Index).Trim()
    $questionText = [regex]::Replace($questionText, "\s*\[[^\]]+\]\s*", "").Trim()

    return [ordered]@{
        question = $questionText
        options = $options
    }
}

if ([string]::IsNullOrWhiteSpace($SourceDocx)) {
    $desktopDocx = Get-ChildItem -Path "D:\Users\ASUS\Desktop" -Filter "*.docx" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $desktopDocx) {
        throw "No DOCX file was found on D:\Users\ASUS\Desktop. Pass -SourceDocx explicitly."
    }

    $SourceDocx = $desktopDocx.FullName
}

if (-not (Test-Path -LiteralPath $SourceDocx)) {
    throw "Source DOCX not found: $SourceDocx"
}

$paragraphs = Get-DocxParagraphs -Path $SourceDocx
$answerStart = -1
for ($i = 0; $i -lt $paragraphs.Count; $i++) {
    if ($paragraphs[$i] -eq $MarkerReference) {
        $answerStart = $i
        break
    }
}

if ($answerStart -lt 0) {
    throw "Could not find the answer section marker."
}

$answerMap = Parse-AnswerMap -Lines $paragraphs[($answerStart + 1)..($paragraphs.Count - 1)]
$questions = New-Object System.Collections.Generic.List[object]
$sourceQuestionNumbers = New-Object System.Collections.Generic.HashSet[int]
$skippedMissingAnswer = New-Object System.Collections.Generic.List[int]
$skippedBadOptions = New-Object System.Collections.Generic.List[int]
$invalidAnswers = New-Object System.Collections.Generic.List[string]

foreach ($line in $paragraphs[0..($answerStart - 1)]) {
    $dotPattern = "\." + [regex]::Escape($FullWidthDot)
    $match = [regex]::Match($line, "^\s*(\d+)[" + $dotPattern + "]\s*(.+)$")
    if (-not $match.Success) {
        continue
    }

    $number = [int]$match.Groups[1].Value
    [void]$sourceQuestionNumbers.Add($number)
    $body = $match.Groups[2].Value.Trim()

    if (-not $answerMap.ContainsKey($number)) {
        $skippedMissingAnswer.Add($number)
        continue
    }

    $type = if ($number -le 2001) {
        "single"
    } elseif ($number -le 3167) {
        "multiple"
    } else {
        "truefalse"
    }

    $rawAnswer = [string]$answerMap[$number]
    if ($type -eq "truefalse") {
        $answerKeys = if ($rawAnswer -eq $TextTrue) { @("A") } else { @("B") }
        $questions.Add([ordered]@{
            id = "t_$number"
            number = $number
            type = $type
            question = [regex]::Replace($body, "\s*\[[^\]]+\]\s*", "").Trim()
            options = @(
                [ordered]@{ key = "A"; text = $TextTrue },
                [ordered]@{ key = "B"; text = $TextFalse }
            )
            answer = $answerKeys
        })
        continue
    }

    $parsed = Extract-Options -Body $body
    if ($null -eq $parsed) {
        $skippedBadOptions.Add($number)
        continue
    }

    $optionKeys = @($parsed.options | ForEach-Object { $_.key })
    $answerKeys = @($rawAnswer.ToCharArray() | ForEach-Object { [string]$_ })
    $unknownKeys = @($answerKeys | Where-Object { $optionKeys -notcontains $_ })
    if ($unknownKeys.Count -gt 0) {
        $invalidAnswers.Add("$number => $rawAnswer")
    }

    $prefix = if ($type -eq "single") { "s" } else { "m" }
    $questions.Add([ordered]@{
        id = "$($prefix)_$number"
        number = $number
        type = $type
        question = $parsed.question
        options = $parsed.options
        answer = $answerKeys
    })
}

$maxQuestionNumber = 4403
$missingQuestionNumbers = New-Object System.Collections.Generic.List[int]
for ($number = 1; $number -le $maxQuestionNumber; $number++) {
    if (-not $sourceQuestionNumbers.Contains($number)) {
        $missingQuestionNumbers.Add($number)
    }
}

$answerOnlyNumbers = @($answerMap.Keys | Where-Object { -not $sourceQuestionNumbers.Contains([int]$_) } | Sort-Object)
$singleCount = @($questions | Where-Object { $_.type -eq "single" }).Count
$multipleCount = @($questions | Where-Object { $_.type -eq "multiple" }).Count
$truefalseCount = @($questions | Where-Object { $_.type -eq "truefalse" }).Count

$bank = [ordered]@{
    meta = [ordered]@{
        title = $BankTitle
        description = $BankDescription
        source = $SourceDocx
        generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        version = "1.0"
    }
    stats = [ordered]@{
        total = $questions.Count
        single = $singleCount
        multiple = $multipleCount
        truefalse = $truefalseCount
    }
    questions = $questions
}

$outputDir = Split-Path -Parent $OutputJson
if (-not (Test-Path -LiteralPath $outputDir)) {
    [void](New-Item -ItemType Directory -Path $outputDir -Force)
}

$json = $bank | ConvertTo-Json -Depth 12
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $outputDir).Path + "\questions.json", $json, $utf8NoBom)

$report = New-Object System.Text.StringBuilder
[void]$report.AppendLine("# Question Bank Report")
[void]$report.AppendLine("")
[void]$report.AppendLine("- Source: " + $SourceDocx)
[void]$report.AppendLine("- Paragraphs: $($paragraphs.Count)")
[void]$report.AppendLine("- Source question count: $($sourceQuestionNumbers.Count)")
[void]$report.AppendLine("- Imported question count: $($questions.Count)")
[void]$report.AppendLine("- Single: $singleCount")
[void]$report.AppendLine("- Multiple: $multipleCount")
[void]$report.AppendLine("- True/False: $truefalseCount")
[void]$report.AppendLine("- Missing question numbers in source: $($missingQuestionNumbers -join ', ')")
[void]$report.AppendLine("- Skipped because answer is missing: $($skippedMissingAnswer -join ', ')")
[void]$report.AppendLine("- Skipped because options could not be parsed: $($skippedBadOptions -join ', ')")
[void]$report.AppendLine("- Answer-only numbers: $($answerOnlyNumbers -join ', ')")
[void]$report.AppendLine("- Invalid answers: $($invalidAnswers -join ', ')")
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $ReportPath)).Path + "\" + (Split-Path -Leaf $ReportPath), $report.ToString(), $utf8NoBom)

Write-Host "Wrote $OutputJson"
Write-Host "Imported $($questions.Count) questions: single=$singleCount multiple=$multipleCount truefalse=$truefalseCount"
if ($skippedMissingAnswer.Count -gt 0) {
    Write-Host "Skipped missing answers: $($skippedMissingAnswer -join ', ')"
}
