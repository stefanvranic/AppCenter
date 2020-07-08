# AppCenter automated builds with a report #  

Powershell script allows user to build all branches for an application in [AppCenter] and get a report. 
**Technologies and Tools:** | Powershell  | AppCenter | API 
---|---|---|---

### Pre-requirements: ###  
1 Registred account in AppCenter  
2 Existing Application with configured branches. If branches are not configured, user might get an error  
3 User API token  

### Execution details  

1 User will be prompted to enter following data:  
 - Appcenter account name  
 - Application  name  
 - API token  

2 All branches will be queued for building  
3 After all branches are built a report will be provided in the console  


[AppCenter]: https://appcenter.ms/  