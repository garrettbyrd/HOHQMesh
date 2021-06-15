# The Control Input

The meshing of the model is controlled by the *CONTROL_INPUT* block of the input control file, which gives all of the commands needed to mesh the model. Actually, there are not a lot of commands at the moment, so that’s not too bad. The control block is

	\begin{CONTROL_INPUT}
	...
	\end{CONTROL_INPUT}

Inside the control input block the *RUN\_PARAMETERS*, *BACKGROUND\_GRID*, *SMOOTHER*, and any number of *REFINEMENT\_CENTER*s and *REFINEMENT\_LINE*s  are defined.

## The Run Parameters<a name="RunParameters"></a>

The *RUN\_PARAMETERS* block defines the file information and the polynomial order at which the boundary curves will be defined in the mesh file. Three files can be output by the mesher. The first is the actual mesh file. The second is a tecplot format file that can be used to visualize the mesh. The free programs VisIt or Paraview can be used to plot tecplot files. The final file (optional) is to report mesh statistics, like the distribution of largest angle, Jacobian, etc. See the “Verdict Library Reference Manual” by Stimpson et al. if you are interested to learn about the different shape quality measures. Include a unix style path to choose the directory for the results.

The RUN_PARAMETERS block is:

	\begin{RUN_PARAMETERS}
		mesh file name   = MeshFileName.mesh
		plot file name   = PlotName.tec
		stats file name  = StatsName.txt
		mesh file format = ISM OR ISM-v2
		polynomial order = 6
		plot file format = skeleton OR sem
	\end{RUN_PARAMETERS}

The names can be anything, since they are simply text files. However the “.tec” extension on the plot file will help VisIt/Paraview know how to read it. If you don’t want a file created, simply choose the name to be *none*. 

In the current version of  HOHQMesh, there are two mesh file formats, “ISM” which stands for “Implementing Spectral Methods” . This is the file format described in the book by David A. Kopriva. The other format is “ISM-v2”, which provides the edge information needed by the approximations so that the edge generation algorithms in the appendix of the book are not needed. See the section in this manual on ISM-v2 for a description of the additional information provided. In the future, other file formats may be implemented, too. Finally, high order boundary information is conveyed by outputting an interpolant of the specified order. That information can be viewed using the “sem” plot file format.

## The Background Grid<a name="BackgroundGrid"></a>

The meshing algorithm starts with a uniform background grid. If an outer boundary is specified in the model, HOHQMesh will create this background grid using the extents of the outer boundary and the background grid size specified in the *BACKGROUND\_GRID* block. If there is no outer boundary, then the background grid must be specified in the control input. The *BACKGROUND\_GRID* block specifies the coordinates of the lower left corner of the grid, the grid size in each coordinate direction, and the number of  grid cells in each direction:

	\begin{BACKGROUND_GRID}
		x0 = [-10.0, -10.0, 0.0]
		dx = [2.0, 2.0, 0.0]
		N  = [10,10,0]
	\end{BACKGROUND_GRID}

The example above creates a uniform grid with lower left corner at (-10,10) and upper right corner at (10,10).

Alternatively, if there is an outer boundary curve, you want to specify the background grid size and let HOHQMesh compute the rest of the parameters:

	\begin{BACKGROUND_GRID}
		background grid size = [2.0,2.0,0.0]
	\end{BACKGROUND_GRID}

## The Smoother<a name="Smoother"></a>
It is generally necessary to smooth the mesh after it is generated. Smoothing is done by the Smoother. 

The *SPRING\_SMOOTHER* uses a spring-dashpot model and time relaxation to smooth the mesh. There are two spring topologies “LinearSpring” and “LinearAndCrossbarSpring”. The first only has springs between the nodes along the edges. The latter also puts springs along the diagonals of an element. The latter is preferred. The springs have a spring constant associated with them and a dashpot with a damping coefficient. The nodes have mass. The linear ODE system that describes the motion of the nodes is integrated with a forward Euler (Explicit!) approximation for which a time step and number of time steps are given. The *SPRING\_SMOOTHER* block, if one is used (Recommended!)  is

	\begin{SPRING_SMOOTHER}
		smoothing            = ON **or** OFF (Optional)
		smoothing type       = LinearAndCrossbarSpring **or** LinearSpring
		spring constant      = 1.0 (Optional)
		mass                 = 1.0 (Optional)
		rest length          = 0.0 (Optional)
		damping coefficient  = 5.0 (Optional)
		number of iterations = 20
		time step            = 0.1 (Optional)
	\end{SPRING_SMOOTHER}

Just leave out any of the optional parameters if you want the default values to be used. The default values should be sufficient, but the additional flexibility might be useful on occasion.

## Refinement Regions<a name="RefinementRegions"></a>
![Refinements](https://user-images.githubusercontent.com/3637659/121807868-46ae1680-cc56-11eb-8941-c9ad8d259da2.png)
<p align = "center"> Fig. 15. Two refinement centers and a refinement line</p>

Manual scaling of the mesh size can be performed by including any combination of

* Refinement Centers
* Refinement Lines

### Refinement Centers<a name="Centers"></a>
It is possible to ask HOHQMesh to locally refine the mesh at particular locations. This is done with a *REFINEMENT\_CENTER* placed as desired. Two types of centers are available. One is “smooth”, which refines near a specified point and gradually de-refines towards the neighboring mesh size. The other is “sharp”, which keeps the refined size in the neighborhood of the center. The desired mesh size and the size of the center are also parameters. An example of a refinement center is

	\begin{REFINEMENT_CENTER}
		type = smooth **or** sharp
		x0   = [1.0,1.0,0.0]
		h    = 0.20
		w    = 0.5
	\end{REFINEMENT_CENTER}

This will place a center at (1,1,0) with mesh size of 0.2 over a circular region of radius  0.5 . Any number of RefinementCenters can be included. The order in which they are defined is not important.

### Refinement Lines<a name="RefinementLines"></a>
The mesh can also be refined along a line using a *REFINEMENT\_LINE*. Like the centers, there are two types, “smooth” and “sharp”. To refine along a line, include a block of the form 

	\begin{REFINEMENT_LINE}
		type = smooth **or** sharp
		x0   = [-3.5,-3.5,0.0]
		x1   = [3.0,3.0,0.0]
		h    = 0.20
		w    = 0.5
	\end{REFINEMENT_LINE}

Here, *x0* and *x1* are the starting and ending points of the line, *h* is the desired mesh size and *w* tells how far out from the line the refinement extends. An example of center and line refinements can be seen in Fig. 15.
### Refinement Region Definition<a name="RefinementDefinition"></a>

Refinement regions are defined within a *REFINEMENT\_REGIONS* block, e.g.  

	\begin{REFINEMENT_REGIONS}

      \begin{REFINEMENT_LINE}
          type = nonsmooth
          x0   = [-3.0,-3.0,0.0]
          x1   = [3.0,3.0,0.0]
          h    = 0.3
          w    = 0.3
       \end{REFINEMENT_LINE}

       \begin{REFINEMENT_CENTER}
          type = smooth
          x0   = [3.0,-3.0,0.0]
          h    = 0.1
          w    = 0.3
       \end{REFINEMENT_CENTER}

	\end{REFINEMENT_REGIONS}