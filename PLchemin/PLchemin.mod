/*********************************************
 * OPL 12.5 Model
 * Author: seb
 * Creation Date: 18 févr. 2018 at 19:33:51
 *********************************************/

  int n = ...;
 range Rn = 1..n;
 int a[Rn][Rn] = ...;
 
 tuple Subtour { int size; int subtour[Rn]; }
{Subtour} subtours = ...;

 dvar boolean s[Rn]; 
 dvar boolean x[Rn][Rn];
 dvar float+ f[Rn][Rn]; 
 
 minimize sum(i in Rn) s[i];
 
subject to{
   
	// Existence des aretes
	forall (i in Rn, j in Rn)
		donnee: x[i][j] <= a[i][j];
 	  
	// Definition de s (degré sup à 3)
	forall (i in Rn)
		degre: n*s[i] >= sum(j in Rn) (x[i][j]) - 2;
	

	// Nombre d'aretes d'un arbre
	arbre: sum(i in Rn, j in Rn) x[i][j] == n - 1;
	
	// Existance des flots
	forall (i in Rn, j in Rn)
		flot: f[i][j] <= x[i][j];
	
	// Flot à la racine
	racine: sum(j in 2..n) f[1][j] == n - 1;
	  
	// Connexité
	forall(i in 2..n)
	  connexe: sum(j in Rn) x[j][i] == 1;
	  
	// Definition de la contrainte en sous tour
	forall (s in subtours)
       sstour: sum (i in Rn : s.subtour[i] != 0)
          x[minl(i, s.subtour[i])][maxl(i, s.subtour[i])] <= s.size-1;
};

// POST-PROCESSING to find the subtours

// Solution information
int thisSubtour[Rn];
int newSubtourSize;
int newSubtour[Rn];

int visited[i in Rn] = 0;
setof(int) adj[j in Rn] = {i | i in Rn,j in Rn : x[i][j] == 1} union
                              {k | j in Rn,k in Rn : x[j][k] == 1};

execute {

  newSubtourSize = n;
  for (var i in Rn) { // Find an unexplored node
    if (visited[i]==1) continue;
    var start = i;
    var node = i;
    var thisSubtourSize = 0;
    for (var j in Rn)
      thisSubtour[j] = 0;
    while (node!=start || thisSubtourSize==0) {
      visited[node] = 1;
      var succ = start; 
      for (i in adj[node]) 
        if (visited[i] == 0) {
          succ = i;
          break;
        }
                        
      thisSubtour[node] = succ;
      node = succ;
      ++thisSubtourSize;
    }

    writeln("Found subtour of size : ", thisSubtourSize);
    if (thisSubtourSize < newSubtourSize) {
      for (i in Cities)
        newSubtour[i] = thisSubtour[i];
        newSubtourSize = thisSubtourSize;
    }
  }
  if (newSubtourSize != n)
    writeln("Best subtour of size ", newSubtourSize);
}



/*****************************************************************************
 *
 * SCRIPT
 * 
 *****************************************************************************/

main {
    var opl = thisOplModel
    var mod = opl.modelDefinition;
    var dat = opl.dataElements;

    var status = 0;
    var it =0;
    while (1) {
        var cplex1 = new IloCplex();
        opl = new IloOplModel(mod,cplex1);
        opl.addDataSource(dat);
        opl.generate();
        it++;
        writeln("Iteration ",it, " with ", opl.subtours.size, " subtours.");
        if (!cplex1.solve()) {
            writeln("ERROR: could not solve");
            status = 1;
            opl.end();
            break;
        }
        opl.postProcess();
        writeln("Current solution : ", cplex1.getObjValue());

        if (opl.newSubtourSize == opl.n) {
          opl.end();
          cplex1.end();
          break; // not found
        }
          
        dat.subtours.add(opl.newSubtourSize, opl.newSubtour);
		opl.end();
		cplex1.end();
    }

    status;
}
 