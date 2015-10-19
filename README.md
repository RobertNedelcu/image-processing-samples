# image-processing-samples

The only gem/library used is ChunkyPNG; from which, converting an image to an array of rgb values (and visa versa) and getting the image dimensions are the only methods used. Every other aspect of the program was built from scratch.

The complete app takes a satellite image of a track of land and returns both an aggregate tree count
and a resulting image with each individual tree-crown properly outlined. 
As is, the application is more accurate than any of the traditional methods commonly used.

*a full technical demo can be given upon request*

##Explanations for samples from my image processing and tree recognition application:

 *Note: Given the emence amount of pixels in every image and that the majority of the methods need to randomly access pixel values by their position, the very first step is to use the image array given by ChunkyPNG to make an image hash, where the keys are the pixels associated x and y coordinates and the values being an rgb array. The much more    efficient image hash is then used and manipiulated throughout the program.*

###smoothing:

**The Problem:**

Before the computer-vision aspect of the program can be implemented, the image must be transformed via a series of image processing methods. The first of these steps is to smooth the image to reduce noise. For this I implemented the Gaussian Blur technique, which, in short, iterates through each pixel and applies a new rgb value equal to the sum of weighted rgb values of every other pixel (its 5x5 pixel neighborhood is sufficient) - where each pixels associated weight is given by a formula with input variables being distance from the working pixel and a chosen standard deviation.Given the vast amount of rgb values and weights every pixel in the image must uniquely calculate, a technique that minimize the compuations required per iteration needs to be utilized.

**The Solution:**

Using the original image hash as a parameter I create a new hash where each position-key has a value equal to a multi-dimensional array of the rgb values of the two pixels above, the current pixel, and the two pixels below. Then, I calculate the corresponding weights for each position in the 5x5 neighborhood where the working pixel is the center. With this information, I can now iterate through each pixel of the original image hash and: plug in the current position along with the positions of the 4 pixels on either side into the 5-pixel vertical lines hash and store each line into an ordered array begining with the left-most line; multiply each red, green, and blue value by its correspong weight - which is infered by its index position in the array of lines (instead of uniquely calculating each values distance from center); then take the sum of each rgb weighted value as the new smoothed value for that pixel.   

###segmenting:

**The Problem:**

Once all the likely tree pixels have been indentified, individual trees are found using local level maximas (level with a brightness value greater than all its neighboring levels). However, in some cases, grouped tree clusters share the same local level maxima and segmentation is required to seperate each indivdual tree in the cluster as its own blob(of pixels). The primary indicator for this occurence is a local level maxima that is above thresholds for both size and allowed shape-abonormality (not round enough). 

**The Solution:**

Each level maxima is first checked to see if it is greater than the size threshold. If it is greater than the size threshold, the standard deviation of its boundary pixels from the center is found to see if its st_dev is outside the accesptable range for roundness (the two steps are seperate for efficiency purposes, as the vast morjority are below the size threshold and do not need to be checked against the much more computationally intensive st_dev test). If it's st_dev is too great, it is then segmented. Segmentation invloves finding the pixel position with greatest area contained by its minimum radi(to boundary), then with that area removed from the working pixel cluster the processes is repeated once more. Now with two segments, each remainging pixel is added to the segment whose center it is closest to. The two segments are then each checked to see if further segmentation is required.    

###drawing_methods:

**The Problem:**

Once each tree has been indentified, one of the primary difficulties in drawing around indiviual tree crowns (for human visualization) is that many trees are grouped in clusters with overlapping canaopies. I found that traditional methods were insuficient for visualization purposes. The goal is to take each blob of pixels (that represent an indivual tree crown) and draw a roughly circle-like outline around it so that a human can easily distinguish each tree identified; however, methods that simply draw a circle yields a result that either creates a confusing mess of overlapping circles (in grouped tree-clusters) or, if the size of the circle is proportionally reduced to prevent (most) overlaps, an inadequate amount of the tree crown is encompassed.

**The Solution:**

I created a series of methods that draws a circle-like oval which encompasses nearly 100% of every blob with almost no cases of overlap. To draw the oval I created a method that draws a Bezier Curve using two vector points and two handle points as parameters. So for each blob, the two best oppossing boundary positions have to be found and designated as the vector points. Then, the portion of the blob on either side of each vector point is used to determine the angle, length, and subsequent position of the associated handle point.  Finally, the Bezeir Curve method is called twice using the same two vector points for each, but with different pairs of handle points for each associated side. The result is an oval created from two connecting curves. 

