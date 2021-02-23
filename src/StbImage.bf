using System;
using System.IO;

namespace StbImageSharp
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	static class StbImage
	{
		public static String LastError;

		public const int STBI__ZFAST_BITS = 9;

		public delegate void idct_block_kernel(uint8* output, int out_stride, int16* data);

		public delegate void YCbCr_to_RGB_kernel(
			uint8* output, uint8* y, uint8* pcb, uint8* pcr, int count, int step);

		public delegate uint8* Resampler(uint8* a, uint8* b, uint8* c, int d, int e);

		public static String stbi__g_failure_reason;
		public static int stbi__vertically_flip_on_load;

		public class stbi__context
		{
			public int img_n = 0;
			public int img_out_n = 0;
			public int img_x = 0;
			public int img_y = 0;

			public this(Stream stream)
			{
				Stream = stream;
			}

			public Stream Stream
			{
				get;
			}
		}

		public struct img_comp
		{
			public int id;
			public int h, v;
			public int tq;
			public int hd, ha;
			public int dc_pred;

			public int x, y, w2, h2;
			public uint8* data;
			public void* raw_data;
			public void* raw_coeff;
			public uint8* linebuf;
			public int16* coeff; // progressive only
			public int coeff_w, coeff_h; // number of 8x8 coefficient blocks
		}

		public class stbi__jpeg
		{
			public readonly uint16[][] dequant;

			public readonly int16[][] fast_ac;
			public readonly stbi__huffman[] huff_ac = new stbi__huffman[4];
			public readonly stbi__huffman[] huff_dc = new stbi__huffman[4];
			public int app14_color_transform; // Adobe APP14 tag
			public int code_bits; // number of valid bits

			public uint code_buffer; // jpeg entropy-coded buffer
			public int eob_run;

			// kernels
			public idct_block_kernel idct_block_kernel;

			// definition of jpeg image component
			public img_comp[] img_comp = new img_comp[4];

			// sizes for components, interleaved MCUs
			public int img_h_max, img_v_max;
			public int img_mcu_w, img_mcu_h;
			public int img_mcu_x, img_mcu_y;
			public int jfif;
			public uint8 marker; // marker seen while filling entropy buffer
			public int nomore; // flag if we saw a marker so must stop
			public int[] order = new int[4];

			public int progressive;
			public Resampler resample_row_hv_2_kernel;
			public int restart_interval, todo;
			public int rgb;
			public stbi__context s;

			public int scan_n;
			public int spec_end;
			public int spec_start;
			public int succ_high;
			public int succ_low;
			public YCbCr_to_RGB_kernel YCbCr_to_RGB_kernel;

			public this()
			{
				for (var i = 0; i < 4; ++i)
				{
					huff_ac[i] = new stbi__huffman();
					huff_dc[i] = new stbi__huffman();
				}

				fast_ac = new int16[4][];
				for (var i = 0; i < fast_ac.Count; ++i)
					fast_ac[i] = new int16[1 << STBI__ZFAST_BITS];

				dequant = new uint16[4][];
				for (var i = 0; i < dequant.Count; ++i)
					dequant[i] = new uint16[64];
			}
		}

		public class stbi__resample
		{
			public int hs;
			public uint8* line0;
			public uint8* line1;
			public Resampler resample;
			public int vs;
			public int w_lores;
			public int ypos;
			public int ystep;
		}

		public struct stbi__gif_lzw
		{
			public int16 prefix;
			public uint8 first;
			public uint8 suffix;
		}

		public class stbi__gif : IDisposable
		{
			public uint8* _out_;
			public uint8* background;
			public int bgindex;
			public stbi__gif_lzw* codes = (stbi__gif_lzw*)stbi__malloc(8192 * sizeof(stbi__gif_lzw));
			public uint8* color_table;
			public int cur_x;
			public int cur_y;
			public int delay;
			public int eflags;
			public int flags;
			public int h;
			public uint8* history;
			public int lflags;
			public int line_size;
			public uint8* lpal;
			public int max_x;
			public int max_y;
			public uint8* pal;
			public int parse;
			public int ratio;
			public int start_x;
			public int start_y;
			public int step;
			public int transparent;
			public int w;

			public this()
			{
				pal = (uint8*)stbi__malloc(256 * 4 * sizeof(uint8));
				lpal = (uint8*)stbi__malloc(256 * 4 * sizeof(uint8));
			}

			public void Dispose()
			{
				if (pal != null)
				{
					CRuntime.free(pal);
					pal = null;
				}

				if (lpal != null)
				{
					CRuntime.free(lpal);
					lpal = null;
				}

				if (codes != null)
				{
					CRuntime.free(codes);
					codes = null;
				}
			}

			public ~this()
			{
				Dispose();
			}
		}

		private static void* stbi__malloc(int size)
		{
			return CRuntime.malloc((uint64)size);
		}

		private static void* stbi__malloc(uint64 size)
		{
			return stbi__malloc((int)size);
		}

		private static int stbi__err(String str)
		{
			LastError = str;
			return 0;
		}

		public static void stbi__gif_parse_colortable(stbi__context s, uint8* pal, int num_entries, int transp)
		{
			int i;
			for (i = 0; i < num_entries; ++i)
			{
				pal[i * 4 + 2] = stbi__get8(s);
				pal[i * 4 + 1] = stbi__get8(s);
				pal[i * 4] = stbi__get8(s);
				pal[i * 4 + 3] = (uint8)(transp == i ? 0 : 255);
			}
		}

		public static uint8 stbi__get8(stbi__context s)
		{
			return s.Stream.Read<uint8>();
		}

		public static void stbi__skip(stbi__context s, int skip)
		{
			s.Stream.Seek(skip, .Relative);
		}

		public static void stbi__rewind(stbi__context s)
		{
			s.Stream.Seek(0, .Absolute);
		}

		public static int stbi__at_eof(stbi__context s)
		{
			return s.Stream.Position == s.Stream.Length ? 1 : 0;
		}

		public static int stbi__getn(stbi__context s, uint8* buf, int size)
		{
			int i = 0;
			for(; i < size; ++i)
			{
				if (stbi__at_eof(s) == 1)
				{
					break;
				}

				buf[i] = stbi__get8(s);

			}

			return i;
		}
	}
}