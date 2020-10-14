var axios = require('axios');

var config = {
  method: 'post',
  url: 'http://127.0.0.1:36677/upload',
  headers: { }
};

axios(config)
  .then(function (response) {
    var resultObject = response.data;
    if (resultObject['success'] == true){
      var results = resultObject.result
      console.log(results[0])
    } else {
      console.log("error")
    }
    // console.log(JSON.stringify(response.data));
  })
  .catch(function (error) {
    console.log("error");
});

