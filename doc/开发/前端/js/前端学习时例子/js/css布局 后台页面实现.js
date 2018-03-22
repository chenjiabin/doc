function myfunc(nid) {
    var oneid = document.getElementById(nid);
    var towdiv = oneid.getElementsByTagName('div')[0];
    var value = towdiv.className;

    if(value){
        towdiv.classList.remove('hide');
    }else {
        towdiv.classList.add('hide')
    }
}




