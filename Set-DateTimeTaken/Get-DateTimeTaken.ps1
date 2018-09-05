class FileDetails {

    static [String] GetDirectoryName([String]$path){ return Split-Path -Path $path }

    static [String] GetFileName([String]$path) { return Split-Path -Leaf $path }

    static [psobject] GetMetadata([String]$path) {         
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace([FileDetails]::GetDirectoryName($path))
        $file = $folder.ParseName([FileDetails]::GetFileName($path))
        
        $metaData = New-Object psobject
        for($i = 0; $i -le 266; $i++){
            if($folder.GetDetailsOf($file, $i)){
                $hash += @{$($folder.GetDetailsOf($folder.items, $i)) = $folder.GetDetailsOf($file, $i)}
                $propertyName = $folder.GetDetailsOf($folder.items, $i)
                $details = $folder.GetDetailsOf($file, $i)
                $metaData | Add-Member $hash
                $hash.Clear()
            }
        }
        return $metaData
    }    
}

class GetDateTakenStrategy {
        [String[]] GetDateTimeFormats() {
            throw [System.NotImplementedException]
        }

        [String] GetDateTimeTakenInternal(){
            throw [System.NotImplementedException]
        }

        [bool] TryGetDateTimeTaken([String]$path) {
            $s = $this.GetDateTimeTakenInternal($path);

            [ref]$dateTimeTaken = Get-Date;
            [String[]]$dateTimeFormats = $this.GetDateTimeFormats();
            [bool]$result = [DateTime]::TryParseExact(
                $s, 
                $dateTimeFormats, 
                [System.Globalization.CultureInfo]::InvariantCulture, 
                [System.Globalization.DateTimeStyles]::None, 
                $dateTimeTaken);
            return $result;
        }

        [DateTime] GetDateTimeTaken([String]$path) {
            $s = $this.GetDateTimeTakenInternal($path);
            [String[]]$dateTimeFormats = $this.GetDateTimeFormats();         
            [DateTime]$result = [DateTime]$dateTime = [DateTime]::ParseExact(
                $s, 
                $dateTimeFormats, 
                [System.Globalization.CultureInfo]::InvariantCulture, 
                [System.Globalization.DateTimeStyles]::None);
            return $result;
        }
}

class GetDateTakenFromExifStrategy : GetDateTakenStrategy {
        [String]$LazyDateTime = [String]::Empty;
        [String]$ExpandProperty = "Date taken";    

        [String] ToString() {
            return [String]::Join(".", $this.ExpandProperty, "Strategy");
        }

        [String] RemoveNonPrintableCharactersEx([String]$s) {
            [String]$result = ''

            $pattern = "[^a-zA-Z0-9\s\.\:\/]"
            $result = $s -replace $pattern, ''

            return $result
        }

        [String] RemoveNonPrintableCharacters([String]$s) {
            $encoding = [system.Text.Encoding]::ASCII
            [String]$result = ''

            for($i=0; $i -le $s.Length; $i++){
                $value = [int]$s[$i]
                if($value -lt 32 -or $value -gt 126) {
                    continue
                }
                $result += $s[$i]
            }

            return $result
        }

        [String] GetDateTimeTakenInternal([String]$path){
            if(-Not [String]::IsNullOrEmpty($this.LazyDateTime)){
                return $this.LazyDateTime;
            }

            $dateTaken = [FileDetails]::GetMetadata($path) | select -ExpandProperty $this.ExpandProperty;
            $this.LazyDateTime = $this.RemoveNonPrintableCharactersEx($dateTaken)        
            return $this.LazyDateTime;
        }

        [String[]] GetDateTimeFormats(){
            [String[]]$dateTimeFormats = @( 
                "dd.MM.yyyy HH:mm", 
                "dd.MM.yyyy h:mm", 
                "dd.MM.yyyy", 
                "MM/d/yyyy HH:mm tt", 
                "MM/d/yyyy h:mm tt", 
                "MM/dd/yyyy HH:mm tt", 
                "MM/dd/yyyy h:mm tt",
                "M/d/yyyy HH:mm tt",
                "M/d/yyyy h:mm tt",
                "M/dd/yyyy HH:mm tt",
                "M/dd/yyyy h:mm tt");
            return $dateTimeFormats;
        }        
    }

class GetDateTakenDefaultStrategy : GetDateTakenStrategy {
    
    [String]$FallBackDateTime;

    [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @(
            "dd.MM.yyyy HH:mm", 
            "dd.MM.yyyy h:mm", 
            "dd.MM.yyyy", 
            "MM/d/yyyy HH:mm tt", 
            "MM/d/yyyy h:mm tt", 
            "MM/dd/yyyy HH:mm tt", 
            "MM/dd/yyyy h:mm tt");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        if([String]::IsNullOrEmpty($this.FallBackDateTime)) { return $this.FallBackDateTime; }
        return [String]::Join(" ", $this.FallBackDateTime, "08:00");
    }
}

class GetDateTakenStrategy_dv_yyMMdd_HHmmss : GetDateTakenStrategy {
    
   [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @( "yyMMdd_HHmmss");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        [String]$result = [String]::Empty;

        $fileName = [FileDetails]::GetFileName($path)
        $pattern = "^(dv_)(\d{6}_\d{6})-";
        if(-Not [Regex]::IsMatch($fileName, $pattern)) { return $result; }
        $match = [Regex]::Match($fileName, $pattern);

        if($match.Groups.Count -lt 2) { return $result; }
        return $match.Groups[2].Value;
    }
}

class GetDateTakenStrategy_dv_yyMMdd : GetDateTakenStrategy { 

    [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @( "yyMMdd", "yyMMdd HH:mm");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        [String]$result = [String]::Empty;

        $fileName = [FileDetails]::GetFileName($path);
        $pattern = "^(dv_)(\d{6})-";
        if(-Not [Regex]::IsMatch($fileName, $pattern)) { return $result; }
        $match = [Regex]::Match($fileName, $pattern);

        if($match.Groups.Count -lt 2) { return $result; }
        $result = [String]::Join(" ", $match.Groups[2].Value, "08:00");
        return $result;
    }
}

class GetDateTakenStrategy_yyMMdd : GetDateTakenStrategy {     

    [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @( "yyMMdd", "yyMMdd HH:mm");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        [String]$result = [String]::Empty;

        $fileName = [FileDetails]::GetFileName($path);
        $pattern = "^(\d{6})-";
        if(-Not [Regex]::IsMatch($fileName, $pattern)) { return $result; }
        $match = [Regex]::Match($fileName, $pattern);

        if($match.Groups.Count -lt 1) { return $result; }
        $result = [String]::Join(" ", $match.Groups[1].Value, "08:00");
        return $result;        
    }
}

class GetDateTakenStrategy_yyyy_MM_dd : GetDateTakenStrategy {
    # 2011-02-04-гимнастика-кпи-01

    [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @( "yyyy-MM-dd", "yyyy-MM-dd HH:mm");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        [String]$result = [String]::Empty;

        $fileName = [FileDetails]::GetFileName($path);
        $pattern = "^(\d{4}-\d{2}-\d{2})-";
        if(-Not [Regex]::IsMatch($fileName, $pattern)) { return $result; }
        $match = [Regex]::Match($fileName, $pattern);

        if($match.Groups.Count -lt 1) { return $result; }
        $result = [String]::Join(" ", $match.Groups[1].Value, "08:00");
        return $result;        
    }
}

class GetDateTakenStrategy_yyyy_MM_dd_HHmmss : GetDateTakenStrategy {
    # 2012-02-25-211630-блокбастер-каток.avi

    [String[]] GetDateTimeFormats(){
        [String[]]$dateTimeFormats = @( "yyyy-MM-dd-HHmmss");
        return $dateTimeFormats;
    }

    [String]GetDateTimeTakenInternal([String]$path){
        [String]$result = [String]::Empty;

        $fileName = [FileDetails]::GetFileName($path);
        $pattern = "^(\d{4}-\d{2}-\d{2}-\d{6})-";
        if(-Not [Regex]::IsMatch($fileName, $pattern)) { return $result; }
        $match = [Regex]::Match($fileName, $pattern);

        if($match.Groups.Count -lt 1) { return $result; }
        $result = $match.Groups[1].Value;
        return $result;        
    }
}

class DateTimeReceiver{
    
    [String]$FallbackDateTime;    
    [GetDateTakenStrategy[]]$Strategies = @();

    DateTimeReceiver() {
        $this.InitializeStrategies();
    }

    DateTimeReceiver([String]$fallbackDateTime, [Bool]$useCreatedDateTime) {
        $this.InitializeStrategies();
        $this.UseCreatedDateTimeStrategy($useCreatedDateTime);
        $this.UseFallbackDateTimeStrategy($fallbackDateTime);
    }

    [void] InitializeStrategies() {
        $getDateTakenFromExifStrategy = [GetDateTakenFromExifStrategy]::new();
        $dv_yyMMdd = [GetDateTakenStrategy_dv_yyMMdd]::new()
        $dv_yyMMdd_HHmmss = [GetDateTakenStrategy_dv_yyMMdd_HHmmss]::new();
        $yyMMdd = [GetDateTakenStrategy_yyMMdd]::new();
        $yyyy_MM_dd = [GetDateTakenStrategy_yyyy_MM_dd]::new();
        $yyyy_MM_dd_HHmmss = [GetDateTakenStrategy_yyyy_MM_dd_HHmmss]::new();

        $this.Strategies = @( 
            $getDateTakenFromExifStrategy,            
            $dv_yyMMdd_HHmmss,
            $yyyy_MM_dd_HHmmss,
            $dv_yyMMdd,
            $yyyy_MM_dd,            
            $yyMMdd);
    }

    [void] UseCreatedDateTimeStrategy([Bool]$useCreatedDateTime) {  
        if(-Not $useCreatedDateTime) { return; }
              
        $strategy = [GetDateTakenFromExifStrategy]::new();
        $strategy.ExpandProperty = "Date modified";
        $this.Strategies += $strategy;
    }

    [void] UseFallbackDateTimeStrategy([String]$fallbackDateTime) {
        if([String]::IsNullOrEmpty($fallbackDateTime)) { return; }

        $fallbackStrategy = [GetDateTakenDefaultStrategy]::new();
        $fallbackStrategy.FallBackDateTime = $fallbackDateTime;
        $this.Strategies += $fallbackStrategy;
    }

    [DateTime] GetDateTimeTaken([string] $path)
    {
        [DateTime]$result = [DateTime]::MinValue;
            
            foreach($strategy in $this.Strategies) {                             
                if($strategy.TryGetDateTimeTaken($path)) {
                    $result = $strategy.GetDateTimeTaken($path);
                    Write-Host "STRATEGY: " $strategy
                    break;
                }
            }            

            if($result -eq [DateTime]::MinValue) {
                throw [System.InvalidOperationException]
            }
            return $result;
        }
}

class TestClass {
    static Test() {
        $path = "C:\.tmp\";        
        $receiver = [DateTimeReceiver]::new();
        $receiver.UseCreatedDateTimeStrategy($true);
        $dateTimeTaken = $receiver.GetDateTimeTaken($path);
        Write-Host $dateTimeTaken
    }
}

[TestClass]::Test();