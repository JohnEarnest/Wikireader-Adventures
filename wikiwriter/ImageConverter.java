import java.io.*;
import java.awt.image.*;
import javax.imageio.*;

public class ImageConverter {
	public static void main(String[] args) throws Exception {
	
		BufferedImage i = ImageIO.read(new File("SPLASH2.PNG"));
		DataOutputStream o = new DataOutputStream(new FileOutputStream(new File("SPLASH2.IMG")));
		
		// 240x208 1 bit
		for(int y=0; y<208; y++) {
			for(int x=0; x<32; x++) {
				// each byte represents 8 pixels
				// image is logically padded to 32 bytes/row
				byte d = 0;
				for(int b=0; b < 8; b++) {
					int px = (x*8) + b;
					int pixel = (px >= 240) ? 0 : i.getRGB(px, y);
					d <<= 1;
					d |= (pixel & 1);
				}
				o.writeByte(~d); // 0 is off (white), 1 is on (black) so invert bits.
			}
		}
		
		o.flush();
		o.close();
	}
}

