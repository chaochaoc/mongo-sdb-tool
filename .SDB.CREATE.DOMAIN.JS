var db = new Sdb(sdbHost, sdbPort, sdbUser, sdbPwd);
db.createDomain(name, list, {AutoSplit: true});
