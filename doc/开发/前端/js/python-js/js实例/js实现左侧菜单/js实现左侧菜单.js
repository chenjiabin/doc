function mymenu(nid) {
    var selector = document.getElementById(nid);                        //获取id(nid为标签的id属性)
    var value = selector.getElementsByClassName('ppp')[0];              //找到内容标签

    www = value.className;                                              //获取值

    if(www==='ppp'){                                                    //判断值是否为ppp
        value.classList.add('hide');                                    //如果为ppp则代表当前标签已经展开，当点击时收起此标签
    }else { 
        value.classList.remove('hide')                                  //如果不为ppp则代表当前标签未展开，当点击时展开此标签
    }
}



