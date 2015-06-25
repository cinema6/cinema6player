package com.cinema6.renderer.main
{
	import com.cinema6.renderer.main.VastObject;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	
	public class VideoObject
	{
		private var _ready:Boolean = false;
		private var _loader:URLLoader;
		private var _vastObject:VastObject;
		
		public function VideoObject(vastObject:VastObject):void
		{
			_vastObject = vastObject;
			_ready = true;
		}
		
		public function get mediaFile():String
		{
			return _vastObject.mediaFile;
		}
		
		public function get ready():Boolean
		{
			return _ready;
		}
		
		public function get vastObject():VastObject
		{
			return _vastObject;
		}
		
		private function log(msg:String):void
		{
			trace("Cinema6:" + msg);
			
			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call("console.log", "Cinema6:" + msg);
				}
				catch (e:Error)
				{
				}
			}
		}
	}
}