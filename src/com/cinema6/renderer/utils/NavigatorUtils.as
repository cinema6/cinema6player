package com.cinema6.renderer.utils
{
	import flash.external.ExternalInterface;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	
	public class NavigatorUtils
	{
		/**
		 * used to avoid popup blockers
		 */
		public static function navigateToURL(url:*, window:String = "_self", attribute:String = ""):void
		{
			var req:URLRequest = url is String ? new URLRequest(url) : url;
			if (!ExternalInterface.available)
			{
				flash.net.navigateToURL(req, window);
			}
			else
			{
				try
				{
					var strUserAgent:String = String(ExternalInterface.call("function() {return navigator.userAgent;}")).toLowerCase();
					if (strUserAgent.indexOf("msie") != -1 && uint(strUserAgent.substr(strUserAgent.indexOf("msie") + 5, 3)) >= 7)
					{
						ExternalInterface.call("window.open", req.url, window, attribute);
					}
					else
					{
						flash.net.navigateToURL(req, window);
					}
				}
				catch (e:Error)
				{
					flash.net.navigateToURL(req, window);
				}
			}
		}
	}
}