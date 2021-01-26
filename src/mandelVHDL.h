#ifndef __MANDEL_VHDL_H__
#define __MANDEL_VHDL_H__

void mandelVHDL_init();
void mandelVHDL(unsigned char *, double xld, double yld, double xru, double yru);
void mandelVHDL_shutdown();

unsigned ReadNBytes(unsigned offset, unsigned bytes, bool debugPrint=false);

#endif
