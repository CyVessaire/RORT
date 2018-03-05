/*********************************************
 * OPL 12.5 Model
 * Author: seb
 * Creation Date: 13 févr. 2018 at 15:24:07
 *********************************************/

// Data
 
 int n = ...;
 range Rn = 1..n;
 int a[Rn][Rn] = ...;
 
 tuple Subtour { int size; 
 				 int subtour[Rn]; }
{Subtour} subtours = ...;

 dvar int s[Rn] in 0..1; 
 dvar int x[Rn][Rn] in 0..1;
 
 minimize sum(i in Rn) s[i];
 
 subject to{
   
	// Existence des aretes
	forall (i in Rn, j in Rn)
		donnee: x[i][j] <= a[i][j];

	// Double arètes
	forall (i in Rn, j in Rn: j<=i)
		double: x[i][j] == 0;

	// Definition de s (degré sup à 3)
	forall (i in Rn)
		degre: n*s[i] >= sum(j in Rn) (x[i][j] + x[j][i]) - 2;
	
	// Nombre d'aretes d'un arbre
	arbre: sum(i in Rn, j in Rn) x[i][j] == (n - 1);
	
	// Tout sommet touchés
	forall (j in Rn)
		sommet: sum(i in Rn) (x[i][j] + x[j][i]) >= 1;
	
	// Definition de la contrainte en sous tour
	forall (s in subtours)
       sstour: sum (i in Rn, j in Rn : s.subtour[i] != 0 && s.subtour[j] != 0 && s.subtour[i] != s.subtour[j])
          (x[s.subtour[i]][s.subtour[j]]) <= s.size-1;
};

// POST-PROCESSING to find the subtours

// Solution information
int thisSubtour[Rn];
int newSubtourSize;
int newSubtour[Rn];
int newSubtourSize2;
int newSubtour2[Rn];

int visited[i in Rn] = 0;
setof(int) adj[j in Rn] = {i | i in Rn : x[i][j] == 1} union
                              {k | k in Rn : x[j][k] == 1};

execute{
	function AddSommet(connex, sommet) {
      connex[connex.length] = sommet;
    }
}

execute {
    newSubtourSize = n
    newSubtourSize2 = n
    
    for (var i  in Rn) {
        if (visited[i]==1) continue;
        visited[i] = 1
        for (var j in Rn) {
      		thisSubtour[j] = 0;
        }      		
        var connex = new Array();
        AddSommet(connex, i);
	    var itt = 0
	    while (itt < connex.length) {
			var numero = connex[itt];
			for (var j in adj[numero]){
			    if (visited[j]==1) continue;
			    visited[j] = 1
			    AddSommet(connex, j)
			}
			itt+= 1
		}
    	writeln("Found subtour of size : ", connex.length);
	    newSubtourSize = itt;
	    newSubtourSize2 = n - itt;
      	for (i in Rn) {
      	  	if (i <= connex.length) {
	        	newSubtour[i] = connex[i-1];
       		}        	
       		else {
       		    newSubtour[i] = 0;
       		}
       		var test = 0;
       		for (j in Rn){
       		  if (j <= connex.length && connex[j-1] == i) {
       		    test = 1
              }       		    
       		}     
       		if (test == 1){
       			newSubtour2[i] = 0;	
       		}       		
       		else {
       		    newSubtour2[i] = i;
       		}
	    }        	
	}	
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
        writeln("Solution value : ", opl.x.solutionValue);

        if (opl.newSubtourSize == opl.n) {
          opl.end();
          cplex1.end();
          break; // not found
        }
        
        dat.subtours.add(opl.newSubtourSize, opl.newSubtour);
        dat.subtours.add(opl.newSubtourSize2, opl.newSubtour2);
        writeln(opl.newSubtour)
        writeln(opl.newSubtourSize)
        writeln(opl.newSubtour2)
        writeln(opl.newSubtourSize2)
		opl.end();
		cplex1.end();
    }

    status;
}
 
 
 