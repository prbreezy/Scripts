############################################################
# Read below
# To use to script please
# Start up Developer Tools in Google Chrome (or Firefox Firebug).
# Change to Network tab.
# Enable Preserve log setting.
# Open your ColdFusion Administrator login page and login with your password.
# Go back to the Developer Tools and search the Network tab for enter.cfm request.
# Open the Headers of this request and scroll down to Form Data section.
# Copy the value of cfadminPassword and use this as value for $form['cfadminPassword']. This is the Your JS crypted CFadmin password.
######
######
######
############################################################
# Instances you'd like to create
$cfInstances = 'c1in1','c1in2','c1in3','c1in4','c1in5'

# Base path to ColdFusion
$cfBaseDir = 'd:\ColdFusion11'

$form = @{}
$form['cfadminUserId'] = 'admin'
$form['cfadminPassword'] = '[Your JS crypted CFadmin password]'

# Windows service
$service_account = '[Windows Service Username]'
$service_password = '[Windows Service Password]'

# Login and complete instance installation.
$r = Invoke-WebRequest -Uri "http://localhost/CFIDE/administrator/index.cfm?configServer=true" -UseBasicParsing -SessionVariable 'cfAdminSession' -Method POST -Body $form -TimeoutSec 180
# Make sure installation completed.
$r = Invoke-WebRequest -Uri "http://localhost/CFIDE/administrator/index.cfm?configServer=true" -UseBasicParsing -WebSession $cfAdminSession

# Login to coldfusion administrator
$EnterpriseManagerUrl = 'http://localhost/CFIDE/administrator/entman'
$r = Invoke-WebRequest -Uri "http://localhost/CFIDE/administrator/enter.cfm" -UseBasicParsing -WebSession $cfAdminSession -Method POST -Body $form
$r = Invoke-WebRequest -Uri "$EnterpriseManagerUrl/index.cfm" -UseBasicParsing -WebSession $cfAdminSession
$r.Content -cmatch '.*action="(addserver.cfm\?servertype=addlocal[^"]*).*'
$r = Invoke-WebRequest -Uri "$EnterpriseManagerUrl/$($matches[1])" -UseBasicParsing -WebSession $cfAdminSession
$r.Content -cmatch '.*action="(processaddserver.cfm?[^"]*).*'

# Create the instances.
Foreach ($cfInstance in $cfInstances) {
  $form['serverName'] = $cfInstance
  $form['directory'] = "D:\ColdFusion11\$cfInstance"
  # Required: 'cfusion' instance user need Administrator permissions on the local machine or the service cannot created automatically.
  $form['windows_svc'] = 'on'
  $r = Invoke-WebRequest -Uri "$EnterpriseManagerUrl/$($matches[1])" -UseBasicParsing -WebSession $cfAdminSession -Method POST -Body $form -TimeoutSec 180

  # FusionReactor argument may be copied from existing 'cfusion' instance, remove it. FR will be configured later! Otherwise CF service will not start.
  $jvm_config = "$cfBaseDir\$cfInstance\bin\jvm.config"
  if ((Test-Path -path $jvm_config)) {
    $content = Get-Content $jvm_config
    if ($content -match '-javaagent:C:/FusionReactor/(\w+)/fusionreactor.jar=address=(\d{4})\s') {
      $content -replace '-javaagent:C:/FusionReactor/(\w+)/fusionreactor.jar=address=(\d{4})\s','' | Set-Content $jvm_config
      Write-Host "$cfInstance: Broken FusionReactor argument has been removed."
    }
  }

  # Change the "Logon as" user
  $svc = gwmi win32_service -filter "name='ColdFusion 11 Application Server $cfInstance'"
  $r = $svc.StopService()
  # ReturnValues: http://msdn.microsoft.com/en-us/library/windows/desktop/aa384901%28v=vs.85%29.aspx
  $status = $svc.change($null,$null,$null,$null,$null,$null,$service_account,$service_password).ReturnValue
  if ($status -eq 0) {
    # 0 = The request was accepted.
    Write-Host "$cfInstance`: Logon as Service configured successful."
  }
  else {
    Write-Host "$cfInstance`: Logon as Service configuration failed with ReturnCode $status."
  }
  $r = $svc.StartService()
}
