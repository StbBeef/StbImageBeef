using System;
using System.IO;
using System.Collections;
using Stb.Native;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Hebron.Runtime;

namespace StbImageBeef.Testing
{
	static class Program
	{
		private abstract class LoadResult
		{
			public uint8* Data;
			public int32 Width;
			public int32 Height;
			public ColorComponents Components;
			public int TimeInMs;

			public abstract void Load(List<uint8> dataList);
		}

		private class StbImageBeefResult: LoadResult
		{
			public ~this()
			{
				if (Data != null)
				{
					CRuntime.free(Data);
					Data = null;
				}
			}

			public override void Load(List<uint8> dataList)
			{

				Data = ImageResult.RawFromMemory(dataList, ColorComponents.RedGreenBlueAlpha, out Width, out Height, out Components);

			}
		}

		private class StbNativeResult: LoadResult
		{
			public ~this()
			{
				if (Data != null)
				{
					Internal.StdFree(Data);
					Data = null;
				}
			}

			public override void Load(List<uint8> dataList)
			{
				int32 width = 0, height = 0;
				int32 icomp = 0;
				Data = StbNative.stbi_load_from_memory(dataList.Ptr, (int32)dataList.Count, &width, &height, &icomp, (int)ColorComponents.RedGreenBlueAlpha);
				Width = width;
				Height = height;
				Components = (ColorComponents)icomp;
			}
		}

		private class LoadingTimes
		{
			private readonly Dictionary<String, int> _byExtension = new Dictionary<String, int>();
			private readonly Dictionary<String, int> _byExtensionCount = new Dictionary<String, int>();
			private int _total, _totalCount;

			public void Add(String ext, int value)
			{
				var key = new String(ext);

				String matchKey;
				int matchValue;
				if (!_byExtension.TryGet(key, out matchKey, out matchValue)) {
					_byExtension[key] = 0;
					_byExtensionCount[key] = 0;
				} else {
					delete key;
					key = matchKey;
				}

				_byExtension[key] += value;
				++_byExtensionCount[key];
				_total += value;
				++_totalCount;
			}

			public void BuildString(String sb)
			{
				sb.Clear();
				foreach (var pair in _byExtension)
				{
					var key = pair.key;
					var value = pair.value;
					sb.AppendF($"{key}: {value} ms, ");
				}

				sb.AppendF($"Total: {_total} ms");
			}

			public void BuildStringCount(String sb)
			{
				sb.Clear();

				foreach (var pair in _byExtensionCount)
				{
					sb.AppendF($"{pair.key}: {pair.value}, ");
				}

				sb.AppendF(scope $"Total: {_totalCount}");
			}
		}

		private const int LoadTries = 10;
		private static int tasksStarted;
		private static int filesProcessed, filesMatches;
		private static LoadingTimes stbImageSharpTotal = new LoadingTimes();
		private static LoadingTimes stbNativeTotal = new LoadingTimes();

		public static void Log(StringView fmt, params Object[] args)
		{
			String message = scope String();
			message.AppendF(fmt, params args);

			Console.WriteLine($"{Thread.CurrentThread.Id} -- ${message}");
		}

		private static void BeginWatch(Stopwatch sw)
		{
			sw.Restart();
		}

		private static int EndWatch(Stopwatch sw)
		{
			sw.Stop();
			return (int)sw.ElapsedMilliseconds;
		}

		private static T ParseTest<T>(String name, List<uint8> dataList) where T: LoadResult, new, delete
		{
			var sw = scope Stopwatch();

			Log($"With ${name}");
			BeginWatch(sw);

			T result = null;
			for (var i = 0; i < LoadTries; ++i) {
				result = new T();
				result.Load(dataList);
				if (i < LoadTries - 1) {
					delete result;
				}
			}

			var size = result.Width * result.Height * 4;
			Log($"x: {result.Width}, y: {result.Height}, comp: {result.Components}, size: {size}");
			var passed = (int32)(EndWatch(sw) / LoadTries);
			Log($"Span: {passed} ms");

			result.TimeInMs = passed;

			return result;
		}

		public static bool RunTests(String imagesPath)
		{
			var files = Directory.EnumerateFiles(imagesPath, "*.*");

			var threads = new List<Thread>();
			foreach (var file in files)
			{
				var path = new String();
				file.GetFilePath(path);

				Thread thread = new .(new => ThreadProc);
				threads.Add(thread);
				thread.Start(path, false);

				Interlocked.Increment(ref tasksStarted);
			}

			while (true)
			{
				Thread.Sleep(1000);

				if (tasksStarted == 0)
					break;
			}

			foreach(var thread in threads)
			{
				delete thread;
			}

			return true;
		}

		private static void ThreadProc(Object obj)
		{
			String f = (String)obj;
			if (!f.EndsWith(".bmp") && !f.EndsWith(".jpg") && !f.EndsWith(".png") &&
				!f.EndsWith(".jpg") && !f.EndsWith(".psd") && !f.EndsWith(".pic") &&
				!f.EndsWith(".tga") && !f.EndsWith(".hdr"))
			{
				Interlocked.Decrement(ref tasksStarted);
				return;
			}

			bool match = false;
			var err = scope String();

			StbImageBeefResult stbImageBeefResult = null;
			StbNativeResult stbNativeResult = null;

			repeat {
				Log(String.Empty);
				var dt = scope String();
				DateTime.Now.ToLongTimeString(dt);
				Log($"{dt}: Loading {f} into memory");

				var dataList = scope List<uint8>();
				var result = File.ReadAll(f, dataList);

				var ext = scope String();
				Path.GetExtension(f, ext);
				ext.ToLower();

				Log("----------------------------");

				stbImageBeefResult = ParseTest<StbImageBeefResult>("StbImageSharp", dataList);
				stbNativeResult = ParseTest<StbNativeResult>("Stb.Native", dataList);

				if (stbImageBeefResult.Width != stbNativeResult.Width) {
					err.AppendF($"Inconsistent x: StbSharp={stbImageBeefResult.Width}, Stb.Native={stbNativeResult.Width}");
					break;
				}

				if (stbImageBeefResult.Height != stbNativeResult.Height) {
					err.AppendF($"Inconsistent height: StbSharp={stbImageBeefResult.Height}, Stb.Native={stbNativeResult.Height}");
					break;
				}

				if (stbImageBeefResult.Components != stbNativeResult.Components) {
					err.AppendF($"Inconsistent components: StbSharp={stbImageBeefResult.Components}, Stb.Native={stbNativeResult.Components}");
					break;
				}

				var length = stbImageBeefResult.Width * stbImageBeefResult.Height * 4;

				var dataMatches = true;
				for (var i = 0; i < length; ++i) {
					if (stbImageBeefResult.Data[i] != stbNativeResult.Data[i]) {
						err.AppendF($"Inconsistent data: index={i}, StbSharp={(int)stbImageBeefResult.Data[i]}, Stb.Native={(int)stbNativeResult.Data[i]}");
						dataMatches = false;
						break;
					}
				}

				if (!dataMatches) {
					break;
				}

				match = true;

				stbImageSharpTotal.Add(ext, stbImageBeefResult.TimeInMs);
				stbNativeTotal.Add(ext, stbNativeResult.TimeInMs);
			} while(false);

			if (stbImageBeefResult != null) {
				delete stbImageBeefResult;
			}

			if (stbNativeResult != null) {
				delete stbNativeResult;
			}

			if (match)
			{
				Interlocked.Increment(ref filesMatches);
			} else {
				Log($"Error: {err}");
			}

			delete f;

			Interlocked.Increment(ref filesProcessed);
			Interlocked.Decrement(ref tasksStarted);

			var s = scope String();
			stbImageSharpTotal.BuildString(s);
			Log("StbImageSharp - {0}", s);
			s = scope String();
			stbNativeTotal.BuildString(s);
			Log("Stb.Native - {0}", s);
			s = scope String();
			stbImageSharpTotal.BuildStringCount(s);
			Log("Total files processed - {0}", s);
			Log("StbImageSharp/Stb.Native matches/processed - {0}/{1}", filesMatches, filesProcessed);
			Log("Tasks left - {0}", tasksStarted);
			Log("Native Memory Allocations - {0}", MemoryStats.Allocations);
		}

		public static int Main(String[] args)
		{
			if (args == null || args.Count < 1)
			{
				Console.WriteLine("Usage: StbImageBeef.Testing <path_to_folder_with_images>");
				return 1;
			}

			var start = DateTime.Now;

			var res = RunTests(args[0]);
			var passed = DateTime.Now - start;
			Log("Span: {0} ms", passed.TotalMilliseconds);

			var s = scope String();
			DateTime.Now.ToLongTimeString(s);
			Log($"{s} -- ${(res ? "Success" : "Failure")}");

			return res ? 1 : 0;
		}
	}
}