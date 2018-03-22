function my2() {
   $.ajax({
        url:'/ajax/',
        type:'post',
        data:{'user':'test','password':'test'},
        success:function (data) {
            var info = JSON.parse(data);
            var start = info['start'];
            if(start){
                alert(info['info'])
            } else {
                alert(info['error'])
            }
        }
   });
}



