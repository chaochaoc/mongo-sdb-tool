#!/bin/bash

help()
{
	echo -e "Usage: $1 Operation\n"
	echo "Operation:"
	echo "	listDatabases		List all database in the mongodb"
	echo "		-g arg		Filter matching records, eg: -g 'SAT00'"
	echo "		-G		Exclude system dbs, eg:  'admin|config|test|local'"
	echo "		-F 		Write to file './.mongo.database.list'"
	echo "	listCollections		List collection for databases in 'mongo.database.list' "
	echo "		-F		Write to file './.mongo.collection.json'"
	echo "	listIndexes		List index for collections in 'mongo.collection.list'"
	echo "		-I 		Include index '_id_'"
	echo "		-F 		Write to file './.mongo.index.json'"
	echo "	createSdbDomain		Create domain with all data groups"
	echo "		-n arg		Set domain name, default: all_groups"
	echo "	createSdbCL		Create CL from 'mongo.collection.list' to sdb"
	echo "	createSdbIndex		Create Index for all CL in the sdb"
	echo "	exportFromMongo		Export document from mongo"
	echo "		-p arg		Exportd file path, filename be 'dbName.collectionName.json'"
	echo "		-A              Export all document, otherwise export only the first"
	echo "		-I              Export document with field '_id'"
	echo "	importToSdb		Import data to sdb"
	echo "		-p arg		Import json file path"
}

mongoHost=localhost
mongoPort=27017
mongoUser=
mongoPwd=
sdbHost=localhost
sdbPort=11810
sdbUser=sdbadmin
sdbPwd=sdbadmin

which "mongo" > /dev/null
if [ $? -ne 0 ];then
	echo -e "\033[1;31mError: Command 'mongo' not exist.\033[0m"
	exit 1
fi
which "mongoexport" > /dev/null
if [ $? -ne 0 ];then
	echo -e "\033[1;31mError: Command 'mongoexport' not exist.\033[0m"
	exit 1
fi
which "sdb" > /dev/null
if [ $? -ne 0 ];then
	echo -e "\033[1;31mError: Command 'sdb' not exist.\033[0m"
	exit 1
fi
which "sdbimprt" > /dev/null
if [ $? -ne 0 ];then
	echo -e "\033[1;31mError: Command 'sdbimprt' not exist.\033[0m"
	exit 1
fi
if [ -f "authentication" ];then
	mongoHost=`grep mongo.host authentication | cut -d'=' -f2 | sed 's/\r//'`
	mongoPort=`grep mongo.port authentication | cut -d'=' -f2 | sed 's/\r//'`
	mongoUser=`grep mongo.user authentication | cut -d'=' -f2 | sed 's/\r//'`
	mongoPwd=`grep mongo.pswd authentication | cut -d'=' -f2 | sed 's/\r//'`
	sdbHost=`grep sdb.host authentication | cut -d'=' -f2 | sed 's/\r//'`
	sdbPort=`grep sdb.port authentication | cut -d'=' -f2 | sed 's/\r//'`
	sdbUser=`grep sdb.user authentication | cut -d'=' -f2 | sed 's/\r//'`
	sdbPwd=`grep sdb.pswd authentication | cut -d'=' -f2 | sed 's/\r//'`
	sdbDomain=`grep sdb.domain authentication | cut -d'=' -f2 | sed 's/\r//'`
else
	echo -e "\033[1;31mError: File 'authentication' not found.\033[0m"
	exit 1
fi
listDatabases()
{
while getopts "g:FG" arg
do
	case $arg in
		g)
			filter=$OPTARG
			;;
		F)
			file=true
			;;
		G)
			exclude=true
			;;
		?)
			echo -e "\033[1;31mError: Unknown arg '$OPTARG'.\033[0m"
			help 
			exit 1
	esac
done
cmd="mongo --host $mongoHost --port $mongoPort --quiet --eval \"databases = db.adminCommand('listDatabases').databases;for(var i in databases){print(databases[i].name);}\""
if [ "$exclude" = "true" ]; then
	cmd="$cmd | grep -v -E \"admin|config|local|test\""
fi
if [ -n "$filter" ]; then 
	cmd="$cmd | grep  \"$filter\""
fi
if [ "$file" = "true" ]; then
	cmd="$cmd >./.mongo.database.list"
fi
eval $cmd
}


listCollections(){
while getopts "F" arg
do 
	case $arg in 
		F)
			file=true
			;;
		?)
			echo "unknown arg"
			exit 1
	esac
done
list=`cat ./.mongo.database.list | xargs | sed "s#[ ][ ]*#','#g"`
cmd1="mongo --host $mongoHost --port $mongoPort --quiet --eval \"databases=['$list'];
res = {};
for(var i in databases){
        currdb = db.getSiblingDB(databases[i]);
        res[databases[i]] = [];
        collections = currdb.getCollectionNames();
	for(var j in collections){
                currcl = currdb.getCollection(collections[j]);
		if(currcl._shortName != 'system.indexes'){
                	res[databases[i]].push(currcl._shortName);
		}
        }
}
print(JSON.stringify(res));
\""
cmd2="mongo --host $mongoHost --port $mongoPort --quiet --eval \"databases=['$list'];
for(var i in databases){
        currdb = db.getSiblingDB(databases[i]);
	line = databases[i] + ':';
        collections = currdb.getCollectionNames();
        for(var j in collections){
                currcl = currdb.getCollection(collections[j]);
		if(currcl._shortName != 'system.indexes'){
                	line = line + currcl._shortName + ' ';
		}
	}
	print(line)
}
\""
cmd1="$cmd1 | sed \"s/\\\"/'/g\""
if [ "$file" = "true" ]; then
	cmd1="$cmd1 >./.mongo.collection.json"
	cmd2="$cmd2 >./.mongo.collection.list"
	eval $cmd1
fi
eval $cmd2
}

listIndexes()
{
while getopts "IF" arg
do 
	case $arg in
		I)
			include=true
			;;
		F)
			file=true
			;;
		?)
			echo -e "\033[1;31mError: Unknown arg '$OPTARG'.\033[0m"
			help 
			exit 1
	esac
done
list=`cat .mongo.collection.json`
cmd1="mongo --host $mongoHost --port $mongoPort --quiet --eval \"list=$list;
for(var i in list){
	currdb = db.getSiblingDB(i);
	for(var j in list[i]){
		currcl = currdb.getCollection(list[i][j]);
		index = currcl.getIndexes();
		for (var k in index){
			if (index[k].name != '_id_'){
				print(JSON.stringify(index[k]));
			}
		}
	}
}
\""
cmd2="mongo --host $mongoHost --port $mongoPort --quiet --eval \"list=$list;
for(var i in list){
	currdb = db.getSiblingDB(i);
	for(var j in list[i]){
		currcl = currdb.getCollection(list[i][j]);
		print(JSON.stringify(currcl.getIndexes()));
	}
}
\""
cmd3="mongo --host $mongoHost --port $mongoPort --quiet --eval \"list=$list;
res = [];
for(var i in list){
        currdb = db.getSiblingDB(i);
        for(var j in list[i]){
                currcl = currdb.getCollection(list[i][j]);
                index = currcl.getIndexes();
                for (var k in index){
                        if (index[k].name != '_id_'){
                                res.push(index[k]);
                        }
                }
        }
}
print(JSON.stringify(res));
\""
if [ "$file" = "true" ]; then
	cmd3="$cmd3 >./.mongo.index.json"
	eval $cmd3
else
	if [ "$include" = "true" ]; then
		eval $cmd2
	else
		eval $cmd1
	fi
fi
}

createSdbDomain()
{
while getopts 'n:' arg
do
	case $arg in
		n)
			name=$OPTARG
			;;
		?)
			echo -e "\033[1;31mError: Unknown arg '$OPTARG'.\033[0m"
			help 
			exit 1
	esac
done
#cmd="sdb  \"var db = new Sdb('$sdbHost', $sdbPort, '$sdbUser', '$sdbPwd'); db.listReplicaGroups();\""
cmd="sdb -e \"var sdbHost='$sdbHost'; var sdbPort=$sdbPort; var sdbUser='$sdbUser'; var sdbPwd='$sdbPwd';\" -f .SDB.LIST.GROYP.JS"
cmd="$cmd | grep GroupName | grep -v -E \"SYSCatalogGroup|SYSCoord\" | awk -F \": \" '{print \$2}' |xargs |sed 's/.$//'|sed \"s/, /', '/g\""
list=`eval $cmd`
list="['$list']"
if [ -z "$name" ]; then
	name='all_groups'
fi
cmd="sdb -e \"var sdbHost='$sdbHost'; var sdbPort=$sdbPort; var sdbUser='$sdbUser'; var sdbPwd='$sdbPwd'; var name='$name'; var list=$list;\" -f .SDB.CREATE.DOMAIN.JS"
eval $cmd
echo $name>.sdb.domain.name
}

createSdbCL()
{
if [ -z "$sdbDomain" ]; then
	domain=`cat .sdb.domain.name`
else
	domain=$sdbDomain	
fi
list=`cat .mongo.collection.json`
cmd="sdb -e \"var sdbHost='$sdbHost'; var sdbPort=$sdbPort; var sdbUser='$sdbUser'; var sdbPwd='$sdbPwd'; var clList=$list; var domainName='$domain'\" -f .SDB.CREATE.CL.JS"
eval $cmd
}

createSdbIndex()
{
list=`cat .mongo.index.json | sed "s#\"#'#g"`
cmd="sdb -e \"var sdbHost='$sdbHost'; var sdbPort=$sdbPort; var sdbUser='$sdbUser'; var sdbPwd='$sdbPwd'; var list=$list;\" -f .SDB.CREATE.INDEX.JS"
eval $cmd

}

exportFromMongo()
{
while getopts 'p:AI' arg
do
	case $arg in
		p)
			path=$OPTARG
			;;
		A)
			all=true
			;;
		I)
			withid=true
			;;
		?)
			echo -e "\033[1;31mError: Unknown arg '$OPTARG'.\033[0m"
			help 
			exit 1
	esac
done
if [ -z "$path" ]; then
	echo -e "\033[1;31mError: Arg '-p path' must be set.\033[0m"
	exit 1
else
	if [ ! -d "$path" ];then
		echo -e "\033[1;31mError: Dir '$path' not exist.\033[0m"
		exit 1
	fi
fi
cmd1="mongoexport -h $sdbHost:$sdbPort -d $d -c $c "
jscmd="
function format(inputTime){
	var date = new Date(inputTime);
	var y = date.getFullYear();
	var m = date.getMonth() + 1;
	m = m < 10 ? ('0' + m) : m;
	var d = date.getDate();
	d = d < 10 ? ('0' + d) : d;
	var h = date.getHours();
	h = h < 10 ? ('0' + h) : h;
	var minute = date.getMinutes();
	var second = date.getSeconds();
	var millse = date.getMilliseconds();
	minute = minute < 10 ? ('0' + minute) : minute;
	second = second < 10 ? ('0' + second) : second;
	return y+'-'+m+'-'+d+'-'+h+'.'+minute+'.'+second+'.'+millse;
};
db.#COLLECTION_NAME#.find({}, {_id:0}).forEach(function(item){
	for(key in item){
		if(Object.prototype.toString.call(item[key]) == '[object Date]'){
			var obj = {'\$timestamp': format(item[key])};
			item[key] = obj;
		}
	}
	print(JSON.stringify(item));
});
"
if [ "$all" = "true" ] && [ -z "$withid" ]; then
	databases=`cat .mongo.collection.list |awk -F ":" '{print $1}'| xargs`
	for d in $databases
	do 
	    for c in `cat .mongo.collection.list | grep "$d:"|awk -F ":" '{print $2}'`
	    do 
		    jscmd2=`echo $jscmd | sed "s/#COLLECTION_NAME#/$c/g"`
		    echo -e "\033[1;32mInfo:  Start export data for $d.$c \033[0m"
		    mongo $mongoHost:$mongoPort/$d --quiet --eval "$jscmd2" > $path/$d.$c.json
		    
	    done
	done
fi
if [ -z "$all" ]  && [ -z "$withid" ]; then
	d=`head -n1 .mongo.collection.list |awk -F ":" '{print $1}'`
	c=`head -n1 .mongo.collection.list |awk -F ":" '{print $2}'|awk -F " " '{print $1}'`
	jscmd2=`echo $jscmd | sed "s/#COLLECTION_NAME#/$c/g"`
	echo $jscmd2
        mongo $mongoHost:$mongoPort/$d --quiet --eval "$jscmd2" > $path/$d.$c.json
fi
if [ "$all" = "true" ] && [ "$withid" = "true" ]; then
	databases=`cat .mongo.collection.list |awk -F ":" '{print $1}'| xargs`
	for d in $databases
	do 
		for c in `cat .mongo.collection.list | grep "$d:"|awk -F ":" '{print $2}'`
		do 
		    mongoexport -h $mongoHost:$mongoPort -d $d -c $c -o $path/$d.$c.json
		done
	done
fi
if [ -z "$all" ] && [ "$withid" = "true" ]; then
	d=`head -n1 .mongo.collection.list |awk -F ":" '{print $1}'`
	c=`head -n1 .mongo.collection.list |awk -F ":" '{print $2}'|awk -F " " '{print $1}'`
	mongoexport -h $mongoHost:$mongoPort -d $d -c $c -o $path/$d.$c.json
fi
}


importToSdb()
{
while getopts "p:" arg
do
	case $arg in
		p)
			path=$OPTARG
			;;
		?)
			echo -e "\033[1;31mError: Unknown arg '$OPTARG'.\033[0m"
			help 
			exit 1
	esac
done
if [ -z "$path" ]; then
	echo -e "\033[1;31mError: Arg '-p path' must be set.\033[0m"
	exit 1
else
	if [ ! -d "$path" ];then
		echo -e "\033[1;31mError: Dir '$path' not exist.\033[0m"
		exit 1
	fi
fi
for i in `ls $path| grep .json | xargs`
do 
	cs=`echo $i | awk -F "." '{print $1}'`
       	cl=`echo $i | awk -F "." '{print $2}'`
	echo -e "\033[1;32mInfo:  Start import data for $cs.$cl.\033[0m"
	sdbimprt --hosts $sdbHost:$sdbPort -u $sdbUser -w $sdbPwd -c $cs -l $cl --file $path/$cs.$cl.json --type json
done
}


case "$1" in 
	listDatabases)
		listDatabases ${@:2}
		;;
	listCollections)
		listCollections ${@:2}
		;;
	listIndexes)
		listIndexes ${@:2}
		;;
	createSdbDomain)
		createSdbDomain ${@:2}
		;;
	createSdbCL)
		createSdbCL
		;;
	createSdbIndex)
		createSdbIndex
		;;
	exportFromMongo)
		exportFromMongo ${@:2}
		;;
	importToSdb)
		importToSdb ${@:2}
		;;
	*)
		help $0
		exit 1
esac

exit $?
