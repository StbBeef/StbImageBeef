using System;
using System.IO;

namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	static class StbImage
	{
		public static String LastError;

		public const int32 STBI__ZFAST_BITS = 9;


		public static String stbi__g_failure_reason;
		public static int32 stbi__vertically_flip_on_load;

		public class stbi__context
		{
			public int32 img_n = 0;
			public int32 img_out_n = 0;
			public int32 img_x = 0;
			public int32 img_y = 0;

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
			public int32 id;
			public int32 h, v;
			public int32 tq;
			public int32 hd, ha;
			public int32 dc_pred;

			public int32 x, y, w2, h2;
			public uint8* data;
			public void* raw_data;
			public void* raw_coeff;
			public uint8* linebuf;
			public int16* coeff; // progressive only
			public int32 coeff_w, coeff_h; // number of 8x8 coefficient blocks
		}

		public class stbi__jpeg
		{
			public readonly uint16[][] dequant;

			public readonly int16[][] fast_ac;
			public readonly stbi__huffman[4] huff_ac;
			public readonly stbi__huffman[4] huff_dc;
			public int32 app14_color_transform; // Adobe APP14 tag
			public int32 code_bits; // number of valid bits

			public uint32 code_buffer; // jpeg entropy-coded buffer
			public int32 eob_run;

			// kernels
			public function void (uint8* output, int32 out_stride, int16* data) idct_block_kernel;

			// definition of jpeg image component
			public img_comp[] img_comp = new img_comp[4];

			// sizes for components, interleaved MCUs
			public int32 img_h_max, img_v_max;
			public int32 img_mcu_w, img_mcu_h;
			public int32 img_mcu_x, img_mcu_y;
			public int32 jfif;
			public uint8 marker; // marker seen while filling entropy buffer
			public int32 nomore; // flag if we saw a marker so must stop
			public int32[] order = new int32[4];

			public int32 progressive;
			public function uint8* (uint8* a, uint8* b, uint8* c, int32 d, int32 e) resample_row_hv_2_kernel;
			public int32 restart_interval, todo;
			public int32 rgb;
			public stbi__context s;

			public int32 scan_n;
			public int32 spec_end;
			public int32 spec_start;
			public int32 succ_high;
			public int32 succ_low;

			
			public function void (uint8* output, uint8* y, uint8* pcb, uint8* pcr, int32 count, int32 step) YCbCr_to_RGB_kernel;

			public this()
			{
				fast_ac = new int16[4][];
				for (int32 i = 0; i < fast_ac.Count; ++i)
					fast_ac[i] = new int16[1 << STBI__ZFAST_BITS];

				dequant = new uint16[4][];
				for (int32 i = 0; i < dequant.Count; ++i)
					dequant[i] = new uint16[64];
			}
		}

		public class stbi__resample
		{
			public int32 hs;
			public uint8* line0;
			public uint8* line1;

			public function uint8* (uint8* a, uint8* b, uint8* c, int32 d, int32 e) resample;
			public int32 vs;
			public int32 w_lores;
			public int32 ypos;
			public int32 ystep;
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
			public int32 bgindex;
			public stbi__gif_lzw* codes = (stbi__gif_lzw*)stbi__malloc(8192 * sizeof(stbi__gif_lzw));
			public uint8* color_table;
			public int32 cur_x;
			public int32 cur_y;
			public int32 delay;
			public int32 eflags;
			public int32 flags;
			public int32 h;
			public uint8* history;
			public int32 lflags;
			public int32 line_size;
			public uint8* lpal;
			public int32 max_x;
			public int32 max_y;
			public uint8* pal;
			public int32 parse;
			public int32 ratio;
			public int32 start_x;
			public int32 start_y;
			public int32 step;
			public int32 transparent;
			public int32 w;

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

		private static void* stbi__malloc(int32 size)
		{
			return CRuntime.malloc((uint64)size);
		}

		private static void* stbi__malloc(uint64 size)
		{
			return stbi__malloc((int32)size);
		}

		private static int32 stbi__err(String str)
		{
			LastError = str;
			return 0;
		}

		public static void stbi__gif_parse_colortable(stbi__context s, uint8* pal, int32 num_entries, int32 transp)
		{
			int32 i;
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

		public static void stbi__skip(stbi__context s, int32 skip)
		{
			s.Stream.Seek(skip, .Relative);
		}

		public static void stbi__rewind(stbi__context s)
		{
			s.Stream.Seek(0, .Absolute);
		}

		public static int32 stbi__at_eof(stbi__context s)
		{
			return s.Stream.Position == s.Stream.Length ? 1 : 0;
		}

		public static int32 stbi__getn(stbi__context s, uint8* buf, int32 size)
		{
			int32 i = 0;
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