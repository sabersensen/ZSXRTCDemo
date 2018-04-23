var net = require('net');  
var HOST = '192.168.3.22';  
var PORT = 6969;  

var connections = new Array();

var oneSock = null;
var twoSock = null;

// 创建一个TCP服务器实例，调用listen函数开始监听指定端口  
// 传入net.createServer()的回调函数将作为”connection“事件的处理函数  
// 在每一个“connection”事件中，该回调函数接收到的socket对象是唯一的  
net.createServer(function(sock) {  
    // 我们获得一个连接 - 该连接自动关联一个socket对象  
    // if (!oneSock) {
    //     oneSock = sock;
    //     console.log('绑定1号sock');
    // }
    // if (sock.remoteAddress != oneSock.remoteAddress) {
    //     twoSock = sock;
    //     console.log('绑定2号sock');
    // }
    console.log('CONNECTED: ' +  
        sock.remoteAddress + ':' + sock.remotePort);  
        // sock.write('服务端发出：连接成功');  

    // 为这个socket实例添加一个"data"事件处理函数  
    sock.on('data', function(data) {  
        console.log('DATA ' + sock.remoteAddress + ': ' + data);  
        // 回发该数据，客户端将收到来自服务端的数据  
        // sock.write('You said "' + data + '"');
        // sock.write(data);
        var dataObj = JSON.parse(data);
        var user = sock.remoteAddress+':'+sock.remotePort;
        if (dataObj.eventName == "__join") {
            var peersData = {
                "data" : {
                    "connections" : connections,
                    "you" : user,
                },
                "eventName" : "_peers",
            };
            sock.write(JSON.stringify(peersData));
            connections.push(user);
        }else if(dataObj.eventName == "__sendMsg"){
            // if (sock.remoteAddress != oneSock.remoteAddress) {
            //     console.log('发送给' + oneSock.remoteAddress + ': ' + dataObj.content); 
            //     oneSock.write(JSON.stringify(dataObj.data));
            // }else{
            //     console.log('发送给' + twoSock.remoteAddress + ': ' + dataObj.content);  
            //     twoSock.write(JSON.stringify(dataObj.data));
            // }
            sock.write(JSON.stringify(dataObj));

        };


    });  
    // 为这个socket实例添加一个"close"事件处理函数  
    sock.on('close', function(data) {  
        console.log('CLOSED: ' +  
        sock.remoteAddress + ' ' + sock.remotePort);  
        connections.pop(sock.remoteAddress + ':' + sock.remotePort);

    });  
  
}).listen(PORT, HOST);  
  
console.log('Server listening on ' + HOST +':'+ PORT);
