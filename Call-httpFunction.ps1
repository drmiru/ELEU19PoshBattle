

$url = 'https://d-fun-eleu19.azurewebsites.net/api/startvmbackup?'
$key = 'code=KmXRqvxzxhtnQ/sALdSDZ/rQnbPjogjwIH9jpwTAAoi1PEpkhcw9PA=='
$params = '&vaultName=d-bkv-eleu19&vmName=eleusrvu1804'


Invoke-RestMethod -Method Get -Uri ($url + $key + $params)



