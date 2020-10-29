var axios = require('axios');

var host = '127.0.0.1'
var port = '36677'
var uploadUrl = 'http://' + host + ':' + port + '/upload'
var uploadFile = ''
var postData = ''

const args = process.argv;


if (args.indexOf('-p') > -1) {
	port = args[args.indexOf('-p') + 1]
	uploadUrl = 'http://' + host + ':' + port + '/upload'
}

if (args.indexOf('-f') > -1) {
	uploadFile = args[args.indexOf('-f') + 1]
	postData = JSON.stringify({"list": [uploadFile]})
}

function getPostConfig() {
	if (uploadFile == ''){
		var config = {
			method: 'post',
			url: uploadUrl
		};
		return config
	} else {
		var config = {
			method: 'post',
			url: uploadUrl,
			headers: {
				'Content-Type': 'application-json'
			},
			data: postData
		};
		return config
	}
}


var config = getPostConfig()

axios(config)
	.then(function (response) {
		var resultObject = response.data;
		if (resultObject['success'] == true) {
			var results = resultObject.result
			console.log(results[0])
		} else {
			console.log("error")
		}
		// console.log(JSON.stringify(response.data));
	})
	.catch(function () {
		console.log("error");
	});

