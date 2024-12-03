/*
 * Macro template to process multiple images in a folder
 */

// input parameters
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ Integer (label="Median filter radius", value=2) median_filter_radius
#@ String (label = "File suffix", value = ".tif") suffix

// call to the main function "processFolder"
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	///////////// initial cleaning /////////////////
	// close all images
	run("Close All");
	// clear the roi manager
	roiManager("Reset");
	// remove results in result table if there are any
	run("Clear Results");

	///////////// apply pipeline to input images /////////////////
	// get the files in the input folder
	list = getFileList(input);
	list = Array.sort(list);
	// loop over the files
	for (i = 0; i < list.length; i++) {
		// if there are any subdirectories, process them
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		// if current file ends with the suffix given as input parameter, call function "processFile" to process it
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
	
	///////////// save the extracted features /////////////////
	saveAs("Results", output+"/Results.csv");
	// save parameters
	// create results table
	Table.create("Results");
	setResult("Median filter radius", 0, median_filter_radius);
	updateResults();
	// save results
	saveAs("Results", output + File.separator + "parameters.csv");	
	close("Results");
}

function processFile(input, output, file) {
	
	///////////// define nuclei segmentation masks as ROIs /////////////////
	// open image
	open(input+"/"+file);
	// apply median filtering
	run("Median...", "radius=" + median_filter_radius + "");
	// apply Huang thresholding
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	// apply fill holes
	run("Fill Holes");
	// apply binary watershed
	run("Watershed");
	// add ROIs to the ROI manager
	run("Analyze Particles...", "add");
	
	///////////// extract nuclei features from original image /////////////////
	// open image again
	open(input+"/"+file);
	// overlay rois to the image
	roiManager("Show All");
	// extract features
	roiManager("Measure");
	
	///////////// save image to visually inspect the results /////////////////
	// save the image and the rois for visual inspection
	// increase contrast
	run("Enhance Contrast", "saturated=0.35");
	run("8-bit");
	// add ROIs to the image
	run("Flatten");
	// save for visual inspection
	saveAs("png", output + File.separator + file + "_outputVisualInspection.png");

	///////////// clear everything /////////////////
	// close all images
	run("Close All");
	// clear ROI manager
	roiManager("Reset");
}
