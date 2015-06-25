package com.cinema6.renderer.utils
{
	public class NumberUtils
	{
		
		public static function getRandomNum(low:Number, high:Number):Number
		{
			return Math.floor(Math.random() * (1 + high - low)) + low;
		}
		
		public static function getRandomNumWithException(low:Number, high:Number, excluded:Number):Number
		{
			var num:Number = getRandomNum(low, high);
			
			while (num == excluded)
			{
				num = getRandomNum(low, high);
			}
			
			return num;
		}
		
		public static function toMMSS(num:Number):String
		{
			var hours:Number = Math.floor(num / 3600);
			var minutes:Number = Math.floor((num - (hours * 3600)) / 60);
			var seconds:Number = Math.floor(num - (hours * 3600) - (minutes * 60));
			
			var sec:String = String(seconds);
			if (seconds < 10)
			{
				sec = "0" + seconds;
			}
			
			return minutes + ':' + sec;
		}
	}
}