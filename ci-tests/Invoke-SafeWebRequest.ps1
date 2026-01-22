function Invoke-SafeWebRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "GET",
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$Body,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 10000
    )
    
    try {
        # Crear la solicitud web
        $request = [System.Net.WebRequest]::Create($Uri)
        $request.Method = $Method
        $request.Timeout = $Timeout
        
        # Agregar headers CORRECTAMENTE
        foreach ($key in $Headers.Keys) {
            if ($key -eq "Content-Type") {
                $request.ContentType = $Headers[$key]
            } elseif ($key -eq "User-Agent") {
                $request.UserAgent = $Headers[$key]
            } else {
                $request.Headers.Add($key, $Headers[$key])
            }
        }
        
        # Si no hay Content-Type en headers, usar JSON por defecto para POST/PUT/PATCH
        if (-not $request.ContentType -and $Body -and $Method -in @("POST", "PUT", "PATCH")) {
            $request.ContentType = "application/json"
        }
        
        # Si hay cuerpo, agregarlo
        if ($Body -and $Method -in @("POST", "PUT", "PATCH")) {
            $byteArray = [System.Text.Encoding]::UTF8.GetBytes($Body)
            $request.ContentLength = $byteArray.Length
            
            $stream = $request.GetRequestStream()
            $stream.Write($byteArray, 0, $byteArray.Length)
            $stream.Close()
        }
        
        # Obtener respuesta
        $response = $request.GetResponse()
        $responseStream = $response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $content = $reader.ReadToEnd()
        
        # Crear objeto de respuesta personalizado
        $result = [PSCustomObject]@{
            StatusCode = [int]$response.StatusCode
            StatusDescription = $response.StatusDescription
            Content = $content
            Headers = $response.Headers
            Success = $true
            RawResponse = $response
        }
        
        $reader.Close()
        $responseStream.Close()
        $response.Close()
        
        return $result
    }
    catch [System.Net.WebException] {
        # Manejar errores de web
        if ($_.Exception.Response) {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorContent = $reader.ReadToEnd()
            $statusCode = [int]$_.Exception.Response.StatusCode
            
            $reader.Close()
            $errorStream.Close()
            
            return [PSCustomObject]@{
                StatusCode = $statusCode
                StatusDescription = $_.Exception.Response.StatusDescription
                Content = $errorContent
                Error = $true
                Exception = $_.Exception.Message
                Success = $false
            }
        } else {
            return [PSCustomObject]@{
                StatusCode = 0
                Content = ""
                Error = $true
                Exception = $_.Exception.Message
                Success = $false
            }
        }
    }
    catch {
        return [PSCustomObject]@{
            StatusCode = 0
            Content = ""
            Error = $true
            Exception = $_.Exception.Message
            Success = $false
        }
    }
}
