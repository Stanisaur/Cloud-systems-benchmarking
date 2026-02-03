read the header for runPublishers.

runClients still to be made, but almost identical, only since clients are subscribing its easier and we dont
need to manage timings, still need to pop etc

tldr - very nifty and convenient benchmark setup

to view results we open the cluster's grafana dashboard and simply take a snapshot of all the stats and 
we are finished. the only issues as of now:
- need to incorporate the "groups", currently every simulated "bus" in the runPublishers publishes to same subject, i want each subject to be like the num of bus routes in glasgow, and should look like a normal distribution when you plot publishers as histogram with y axis being count

okay extra notes:
we need to simulate 3g/4g bad/median/good conditions. from research online the distribution is heavily
skewed towards good conditions but it gets bad during periods of high use

here is where it gets a little convoluted, we have 2 requirements:
- a server network(at the theoretical datacenter) where download and upload are great
- a 4g cellular network that will have okay download, terrible upload, with some users who are lucky(most users) and a tail end of users who have very bad connection, we are talking 400ms ping 300ms jitter(variation in ping), throughput is NEVER an issue for our use case case an edge device is only listening to <1kb of data every second which has been possible since like 2013

docker run -d --network macvlan_net --ip 192.168.0.21 --user root --sysctl net.ipv4.ip_forward=1 --name snat_gateway_1 nicolaka/netshoot sleep infinity

for wsl2 users:
cannot use docker desktop/docker engine, you need to have docker installed in whatever distro you usually run through wsl as the docker engine maintainers have decided to add a layer between wsl host and docker interface such that macvlan is not possible, despite the fact that by default wsl is already isolated from host, unless configured(what were they thinking???!!!) so best to run on linux native environment, apologies for inconvenience.

you could reserve ips on the router but that is a little messy, its better to just use nmap(<3mb dw) to arp to see if an address is taken and then just take it
if you are windows 11 and running newer wsl2 release, you can just put following in config:
[wsl2]
networkingMode = mirrored
otherwise on windows 10 you ahve to do the following before you casn exectute
thank heavens for this powershell wizard; tldr, windows 10/11 home edition doesnt give you necessary hypervisor tools to make virtual switch like you can in linux, run this, takes like 5 min and requires restart but worth
https://www.reddit.com/r/PowerShell/comments/svs2dw/script_to_install_hyperv_on_windows_1011_home/
once you have that, do ipconfig to get the name of you ethernet(probably just ethernet) and then
then do following config
[wsl2]
networkingMode = bridged
vmSwitch = "WSLBridge"


