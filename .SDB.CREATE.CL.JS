var list = clList;
var domain = domainName;
var db = new Sdb(sdbHost, sdbPort, sdbUser, sdbPwd);
for(var cs in list){
        try{
                db.createCS(cs, {PageSize: 4096, Domain: domain});
		println("Success: Create cs [" + cs + "] successfully");
		cls = list[cs];
                for(var i in cls){
                        try{
                                var currcs = db.getCS(cs);
                                currcs.createCL(cls[i], {ShardingKey: {_id: 1}, ShardingType: "hash", Partition: 4096, AutoSplit: true, ReplSize: 1, Compressed: false});
                        println("Success: Create cl [" + cs + "." + cls[i] + "] successfully ");
			}catch(e){
                                println("Error: Create cl [" + cs + "." + cls[i] + "] failed, msg = " + e);
                        }
                }
        }catch(e){
                println("Error: Create cs [" + cs + "] failed, msg = " + e);
        }
}

