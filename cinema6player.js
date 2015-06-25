var cinema6player = {};
 
cinema6player.getFlashVersion = function () {
	// ie
	try {
		try {
			var axo = new ActiveXObject('ShockwaveFlash.ShockwaveFlash.6');
			try {
				axo.AllowScriptAccess = 'always';
			} catch (e) {
				return '6,0,0';
			}
		} catch (e) {}
		return new ActiveXObject('ShockwaveFlash.ShockwaveFlash').GetVariable('$version').replace(/\D+/g, ',').match(/^,?(.+),?$/)[1];
		// other browsers
	} catch (e) {
		try {
			if (navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin) {
				return (navigator.plugins["Shockwave Flash 2.0"] || navigator.plugins["Shockwave Flash"]).description.replace(/\D+/g, ",").match(/^,?(.+),?$/)[1];
			}
		} catch (e) {}
	}
	return '0,0,0';
}

cinema6player.flashVersion = function(){
	try{
		var version = cinema6player.getFlashVersion().split(',').shift();
		return version
	}catch(e){
		return 0;
	}
}
	
cinema6player.getDefaultSwf = function() {
	return 'player.swf';
}

cinema6player.getPlayer = function(){
	var val = false;
	var obj = document.getElementById("cinema6player");
	try{
		var val = obj.isCinema6player();
		
		if (val){
			return obj;
		}
	}catch(e){
		val = false;
	}
	
	obj = document.getElementById("cinema6player_alt");
	try{
		var val = obj.isCinema6player();
		
		if (val){
			return obj;
		}
	}catch(e){
		val = false;
	}
	
	return null;
}

cinema6player.getPlayerHTML = function() {
	return '<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="__WIDTH__" id="cinema6player" height="__HEIGHT__" align="left" margin="0" style= "margin: 0; padding:0; border: none">' +
	'<param name="movie" value="__SWF__" />' +
	'<param name="quality" value="high" />' +
	'<param name="bgcolor" value="#000000" />' +
	'<param name="play" value="true" />' +
	'<param name="loop" value="false" />' +
	'<param name="wmode" value="opaque" />' +
	'<param name="scale" value="noscale" />' +
	'<param name="salign" value="lt" />' +
	'<param name="flashvars" value="__FLASHVARS__" />' +
	'<param name="allowScriptAccess" value="always" />' +
	'<param name="allowFullscreen" value="true" />' +
	'<!--[if !IE]>-->' +
	'<object type="application/x-shockwave-flash" data="__SWF__" id="cinema6player_alt" width="__WIDTH__" height="__HEIGHT__" margin="0" style= "margin: 0; padding:0; border: none">' +
	'<param name="movie" value="__SWF__" />' +
	'<param name="quality" value="high" />' +
	'<param name="bgcolor" value="#000000" />' +
	'<param name="play" value="true" />' +
	'<param name="loop" value="false" />' +
	'<param name="wmode" value="opaque" />' +
	'<param name="scale" value="noscale" />' +
	'<param name="salign" value="lt" />' +
	'<param name="flashvars" value="__FLASHVARS__" />' +
	'<param name="allowScriptAccess" value="always" />' +
	'<param name="allowFullscreen" value="true" />' +
	'<!--<![endif]-->' +
	'<a href="http://www.adobe.com/go/getflash">' +
	'<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" />' +
	'</a>' +
	'<!--[if !IE]>-->' +
	'</object>' +
	'<!--<![endif]-->' +
	'</object>';
}

cinema6player.getParamCode = function(obj, param, defaultValue, isFirst, prefix){
	var amp = "&";
	var pre = "";
	if (isFirst) amp = "";
	if (prefix) pre = prefix;
	
	if (obj && obj[param]){
		if (typeof obj[param] == "string" && obj[param].length > 0){
			return amp + pre + param + '=' + encodeURIComponent(obj[param]);
		}else if (typeof (obj[param] == "object")){
			var value = "";
			var firstInObj = true;
			for (var i=0;i<obj[param].length;i++){
				if (firstInObj){
					firstInObj = false;
				}else{
					value += "||"
				}
				value += obj[param][i];
			}
			
			return amp + pre + param + '=' + encodeURIComponent(value);
		}
	}
	
	if (defaultValue){
		return amp + pre + param + '=' + defaultValue;
	}
	
	return "";
}
	
cinema6player.setup = function(obj){
	cinema6player.setupObj = obj;
	
	var swf = cinema6player.getDefaultSwf();
	if(obj.swf && obj.swf.length > 0) {
		swf = obj.swf;
	}
	
	var html = cinema6player.getPlayerHTML().replace(/__SWF__/g, swf);
	html = html.replace(/__WIDTH__/g, obj.width);
	html = html.replace(/__HEIGHT__/g, obj.height);
	
	var flashvars = '';

	flashvars += cinema6player.getParamCode(obj, 'adXmlUrl');
	flashvars += cinema6player.getParamCode(obj, 'playerId');
	
	if (obj.params){
		for (var i in obj.params){
			flashvars += cinema6player.getParamCode(obj.params, i, null, false, 'params.');
		}
	}
	
	html = html.replace(/__FLASHVARS__/g, flashvars);
	
	document.getElementById(obj.playerDiv).innerHTML = html;
}

cinema6player.getAdProperties = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.getAdProperties();
	}else{
		return {};
	}
}

cinema6player.setVolume = function(value){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.setVolume(value);
	}else{
		return {};
	}
}

cinema6player.pauseAd = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.pauseAd();
	}else{
		return {};
	}
}

cinema6player.resumeAd = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.resumeAd();
	}else{
		return {};
	}
}

cinema6player.stopAd = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.stopAd();
	}else{
		return {};
	}
}

cinema6player.getDisplayBanners = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.getDisplayBanners();
	}else{
		return [];
	}
}

cinema6player.displayBanners = function(banners){
	var divName = (cinema6player.setupObj) ? cinema6player.setupObj.bannerDiv : "cinema6_comp_banner";
	
	
	if (!banners || banners.length == 0){
		return;
	}
	
	for (var i=0; i<banners.length;i++){
		if (Number(banners[i].width) == 300 && Number(banners[i].height) == 250){
			document.getElementById(divName).innerHTML = banners[i].sourceCode;
			for (var j=0; j<banners[i].viewTrack.length;j++){
				var a = new Image();
				a.src = banners[i].viewTrack[j];
			}
			
			break;
		}
	}
}

cinema6player.loadAd = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.loadAd();
	}else{
		return [];
	}
}

cinema6player.startAd = function(){
	var player = cinema6player.getPlayer();
	
	if (player){
		return player.startAd();
	}else{
		return [];
	}
}