I *really* need to blog about this...

This project is basically my gateway into actually learning VHDL.
I've already succeeded in implementing a straightforward "C-to-VHDL"
translation of the algorithm, with the HW side fully implementing the
computation of a complete frame, storing it in SRAM, and then sending it
back to the main PC over the USB bus.

<a href="https://www.youtube.com/watch?v=yFIbjiOWYFY">
<img src="contrib/snapshotFromVideo.jpg" alt="Mandelbrot in VHDL - real-time zooming video">Mandelbrot in VHDL - real-time zooming video</img></a>

Now I need to find the time... to try to pipeline this - so I can get
one pixel output per cycle.
