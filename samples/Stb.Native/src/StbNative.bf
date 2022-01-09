using System;

namespace Stb.Native
{
	public static class StbNative
	{
		[LinkName("stbi_load_from_memory")]
		public static extern uint8 *stbi_load_from_memory(uint8 *buffer, int32 len, int32 *x, int32 *y, int32 *channels_in_file, int32 desired_channels);
	}
}
