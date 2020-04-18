var indexList = list;
var db = new Sdb(sdbHost, sdbPort, sdbUser, sdbPwd);
for(var i in indexList){
	index = indexList[i];
	names = index.ns.split('.');
	cs = names[0];
	cl = names[1];
	currcs = db.getCS(cs);
	currcl = currcs.getCL(cl);
	try{
		currcl.createIndex(index.name, index.key);
		println('Success: Create index for [' + index.ns + '] successfully');
	}catch(e){
		println('Error: Create index for [' + index.ns + '], msg = ' + e);
	}
}
