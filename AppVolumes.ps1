$body = @{
username = 'lab\vi-admin'
password = 'VMware1!'
}



Invoke-RestMethod -SessionVariable DaLogin -Method Post -Uri "http://$server/cv_api/sessions" -Body $body

#Invoke-RestMethod -WebSession $DaLogin -Method Get -Uri 'http://cs1.lab.local/cv_api/appstacks' | GM

Invoke-RestMethod -WebSession $DaLogin -Method Post -Uri 'http://cs1.lab.local/cv_api/assignments?action_type=Assign&id=1&assignments%5B0%5D%5Bentity_type%5D=User&assignments%5B0%5D%5Bpath%5D=CN%3Dvi-admin%2CCN%3DUsers%2CDC%3Dlab%2CDC%3Dlocal&rtime=true&mount_prefix='

Invoke-RestMethod -WebSession $DaLogin -Method Post -Uri 'http://cs1.lab.local/cv_api/assignments?action_type=unassign&id=1&assignments%5B0%5D%5Bentity_type%5D=User&assignments%5B0%5D%5Bpath%5D=CN%3Dvi-admin%2CCN%3DUsers%2CDC%3Dlab%2CDC%3Dlocal&rtime=true&mount_prefix='