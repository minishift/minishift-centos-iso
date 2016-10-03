
#Creating a CentOS Live ISO

##Please follow below steps on a CentOS 7 machine to create the Live ISO 

```
$ yum install -y livecd-tools
$ curl -O <cfg or ks file>
$ livecd-creator --config /root/centos-7-livedocker.cfg  --fslabel=Image-Label
```
