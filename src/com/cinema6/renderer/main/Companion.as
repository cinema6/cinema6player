package com.cinema6.renderer.main
{
	import com.cinema6.renderer.main.VastObject;
	import com.cinema6.renderer.utils.StringUtils;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	
	public class Companion
	{
		private var _width:Number;
		private var _height:Number;
		private var _url:String;
		private var _clickThrough:String;
		private var _viewTrack:Array;
		private var _sourceCode:String = "";
		
		public function Companion(companion:XML):void {
			_width = width;
			_height = height;
			_url = url;
			_clickThrough = clickThrough;
			_viewTrack = viewTrack;
			
			_width = Number(companion.@width);
			_height = Number(companion.@height);
			
			_url = StringUtils.filterPixel(companion.StaticResource.text());
			_clickThrough = StringUtils.filterPixel(companion.CompanionClickThrough.text());
			
			_viewTrack = new Array;
			
			if (companion.TrackingEvents && companion.TrackingEvents.Tracking) {
				for each (var bannerTracking:XML in companion.TrackingEvents.Tracking) {
					var event:String = bannerTracking.@event;
					if (event.toLocaleLowerCase() == "creativeview" || event.toLocaleLowerCase() == "start") {
						var clickTrack:String = bannerTracking.text();
						clickTrack = StringUtils.filterPixel(clickTrack);
						
						_viewTrack.push(clickTrack);
					}
				}
			}
			
			if (companion.StaticResource.length() > 0) {
				var source:String = companion.StaticResource.text();
				switch (String(companion.StaticResource.@creativeType)) {
					case 'image':
					case 'image/jpeg':
					case 'image/jpg':
					case 'image/gif':
					case 'image/png':
						_sourceCode = '<a href="' + _clickThrough + '" target="_blank"><img src="' + source + '" width="' + _width + '" height="' + _height + '" border="0"></a>';
						break;
					case 'SWF':
					case 'application/x-shockwave-flash':
						_sourceCode = '<object';
						_sourceCode += ' classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="' + width + '" height="' + height + '" id="acudeo_swf">';
						_sourceCode += '<param name="movie" value="' + source + '" />';
						_sourceCode += '<param name="quality" value="high" />';
						_sourceCode += '<param name="wmode" value="transparent" />';
						_sourceCode += '<param name="allowfullscreen" value="true" />';
						_sourceCode += '<param name="allowscriptaccess" value="always" />';
						_sourceCode += '<!--[if !IE]>-->';
						_sourceCode += '<object type="application/x-shockwave-flash" data="' + source + '" width="' + width + '" height="' + height + '" id="acudeo_swf">';
						_sourceCode += '<param name="quality" value="high" />';
						_sourceCode += '<param name="wmode" value="transparent" />';
						_sourceCode += '<param name="allowfullscreen" value="true" />';
						_sourceCode += '<param name="allowscriptaccess" value="always" />';
						_sourceCode += '<!--<![endif]-->';
						_sourceCode += '<a href="http://www.adobe.com/go/getflashplayer">';
						_sourceCode += '<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" />';
						_sourceCode += '</a>';
						_sourceCode += '<!--[if !IE]>-->';
						_sourceCode += '</object>';
						_sourceCode += '<!--<![endif]-->';
						_sourceCode += '</object>';
						break;
					case 'text/html':
						if (_clickThrough != null && _clickThrough != "") {
							_sourceCode = "<a href='" + _clickThrough + "' target='_blank'>" + source + "</a>";
						} else {
							_sourceCode = source;
						}
				}
			} else if (companion.IFrameResource.length() > 0) {
				_sourceCode = '<iframe src="' + companion.IFrameResource.text() + '" width="' + _width + '" height="' + _height + '" border="0" scrolling="no" marginWidth="0" marginHeight="0" frameBorder="no"></iframe>';
			} else if (companion.HTMLResource.length() > 0) {
				if (_clickThrough != null && _clickThrough != "") {
					_sourceCode = "<a href='" + _clickThrough + "' target='_blank'>" + companion.HTMLResource.text() + "</a>";
				} else {
					_sourceCode = companion.HTMLResource.text();
				}
			}
		}
		
		public function get width():Number {
			return _width;
		}
		
		public function get height():Number {
			return _height;
		}
		
		public function get url():String {
			return _url;
		}
		
		public function get clickThrough():String {
			return _clickThrough;
		}
		
		public function get viewTrack():Array {
			return _viewTrack;
		}
		
		public function get sourceCode():String {
			return _sourceCode;
		}
	}
}