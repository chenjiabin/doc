function mymenu(nid) {
    var selector = document.getElementById(nid);
    var value = selector.getElementsByClassName('ppp')[0];

    www = value.className;

    if(www==='ppp'){
        value.classList.add('hide');
    }else {
        value.classList.remove('hide')
    }
}



