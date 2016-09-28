workflow ScaleRelateDB
{
    #支持主从数据库先后升级，避免冲突导致升级失败的情况
   param(
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition="Standard",				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level="S0",
				#设置升级的服务名称
                [Parameter(Mandatory = $true)] 
                [String] $ServerName="kvim8k9w0k",
                #设置升级的数据库名称
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName="pgws"   ,
                #设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $SecondDBEdition="Standard",				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $SecondDBLevel="S1",
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $SecondDBServerName="bmvr2aby7g",
               
				#设置重试次数
                [Parameter(Mandatory = $true)] 
                [Int32] $MaxTimes=3
 )
    Write-output("Begining scale database")
   $VerbosePreference="continue"
    #登录Azure
     $CredSScrpt = Get-AutomationPSCredential -Name 'xuanxun'
         
     Add-AzureAccount -Environment AzureChinaCloud -Credential $CredSScrpt

    #设定默认SubID
    Select-AzureSubscription -SubscriptionId 'put your subscriptionid here'
    
    #处理数据库1
    $msg="正在处理"+$ServerName+"的数据库"+$DatabaseName+" 升级为"+$Level
    Write-output $msg
    TryScale -Edition $Edition -Level $Level -ServerName $ServerName -DatabaseName $DatabaseName -MaxTimes $MaxTimes
    #处理数据库2
    $msg="正在处理"+$SecondDBServerName+"的数据库"+$DatabaseName+" 升级为"+$SecondDBLevel
    Write-output $msg
   TryScale -Edition $SecondDBEdition -Level $SecondDBLevel -ServerName $SecondDBServerName -DatabaseName $DatabaseName -MaxTimes $MaxTimes
    
 Function TryScale{ 
    param(
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition,				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level,
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $ServerName,
                #设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName,
                    #设置重试次数
                [Parameter(Mandatory = $true)] 
                [Int32] $MaxTimes   				
 )     
 Function ScaleDB
{
    param(
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition,				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level,
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $ServerName,
                #设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName
              					
 )
  
            try{
                    $ErrorActionPreference = "Stop"
                    $msg="Trying Update database to Edition:"+$Edition+" Level:" + $Level  
                   Write-Verbose $msg     
                
				   $Database= Get-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName
                                                                   
                  $ServiceObjective= Get-AzureSqlDatabaseServiceObjective -ServerName $ServerName -ServiceObjectiveName $using:Level
                                                                   
                  Set-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName -Edition $using:Edition -ServiceObjective $ServiceObjective -Force -Sync
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
   
    $times=0
    $result=-1  
do{
    $msg="Trying to scale "+$ServerName+" database "+$DatabaseName+" to "+$Level+" times:"+$times
   Write-output $msg   
   $result=ScaleDB -Edition $Edition -Level $Level -ServerName $ServerName -DatabaseName $DatabaseName
        $msg="Scale database result:" + $result
        Write-output $msg
        if($result -eq 0)
        {
            $msg="升级数据库成功！"
            Write-Output $msg;
        }
        if($result -ne 0)
        {
            $msg="升级数据库失败，第"+$times+"次重试中!"
            Write-Output $msg
        }
        #do sleep here
        #start-sleep -s 300
         $times=$times+1   
}
while(($result -eq -1) -and ($times -lt $MaxTimes))
    #当出现错误，超过指定次数时，发送Email到指定邮箱
    if($result -ne 0)
    {
        $cred=Get-AutomationPSCredential -Name "mailaccount"
        Write-output "Sent Mail!"
   #     Send-MailMessage -To "wifeng@microsoft.com"  -Subject "HelloWorld" -Body "Hello World!" -SMTPServer "smtp.163.com" -Credential $cred  -From "wingfeng@163.com" -BodyAsHtml
    }
   
 
  
}
}