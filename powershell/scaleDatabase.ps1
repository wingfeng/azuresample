workflow Main
{
   param(
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition="Premium",				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level="P1",
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $ServerName="",
                #设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName=""   ,
				#设置重试次数
                [Parameter(Mandatory = $true)] 
                [Int32] $MaxTimes=3
 )
    Write-output("Begining scale database")
    $times=0
    $result=-1
    #登录Azure
     $CredSScrpt = Get-AutomationPSCredential -Name 'azureaccount'
         
     Add-AzureAccount -Environment AzureChinaCloud -Credential $CredSScrpt

    #设定默认SubID
    Select-AzureSubscription -SubscriptionId '60509ab7-65a3-43a1-aeb9-b5412f318dde'
         
    while(($result -eq -1) -and ($times -lt $MaxTimes) )
    {
        $msg="Trying to scale "+$ServerName+" database "+$DatabaseName+" to "+$Level+" times:"+$times
        Write-output $msg   
        $result=Scale
        $msg="Scale database result:" + $result
        Write-output $msg
        if($result -eq 0)
        {
            $msg="升级数据库成功！"
            write-output $msg;
        }
        if($result -ne 0)
        {
            $msg="升级数据库失败，第"+$times+"次重试中!"
            Write-output $msg
        }
        #do sleep here
        #start-sleep -s 300
         $times=$times+1   
    }
    #当出现错误，超过指定次数时，发送Email到指定邮箱
    if($result -ne 0)
    {
        $cred=Get-AutomationPSCredential -Name "mailaccount"
        Send-MailMessage -To "wifeng@microsoft.com"  -Subject "HelloWorld" -Body "Hello World!" -SMTPServer "smtp.163.com" -Credential $cred  -From "wingfeng@163.com" -BodyAsHtml
    }
   
   
Function Scale
{
  
            try{
                    $ErrorActionPreference = "Stop"
                    $msg="Trying Update database to Edition:"+$using:Edition+" Level:" + $using:Level  
                   Write-Verbose $msg     
                               
                   $ServerName = $using:ServerName
                   
				   $DatabaseName = $using:DatabaseName
                   
				   $Database= Get-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName
                                                                   
                  $ServiceObjective= Get-AzureSqlDatabaseServiceObjective -ServerName $ServerName -ServiceObjectiveName $using:Level
                                                                   
                  Set-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName -Edition $using:Edition -ServiceObjective $ServiceObjective -Force
            }
        catch 
        {
            $msg="Catched Error:"+  $_
           Write-Warning $msg 
           
            return -1
        }
           Write-Verbose "Scale Database Finished!"
         
           return 0
        
}
}




