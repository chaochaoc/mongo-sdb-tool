println(sdbHost + sdbPort + sdbUser + sdbPwd);
var db = new Sdb(sdbHost, sdbPort, sdbUser, sdbPwd);
var groups = db.listReplicaGroups();
println(groups);
