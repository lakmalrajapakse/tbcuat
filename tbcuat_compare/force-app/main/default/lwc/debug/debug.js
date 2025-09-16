function debug(message = '', obj) {
    if(obj){
        try{
            console.log(message, JSON.parse(JSON.stringify(obj)));
        }catch(err){
            console.log('DEBUG ERR:' + message, obj);
        }
    }else{
        console.log(message);
    }
}
export { debug }