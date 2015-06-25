package com.cinema6.renderer.events
{
	import flash.events.Event;
	
	public class DataEvent extends Event
	{
		private var _data:Object = {};
		
		public function DataEvent(event:String, data:Object)
		{
			super(event, false, false);
			
			_data = data;
		}
		
		public function get data():Object
		{
			return _data;
		}
	}
}