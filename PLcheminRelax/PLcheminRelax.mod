/*********************************************
 * OPL 12.5 Model
 * Author: seb
 * Creation Date: 6 mars 2018 at 15:31:27
 *********************************************/

 int n = ...;
 range Rn = 1..n;
 int a[Rn][Rn] = ...;
 int vois_essai[Rn][Rn] = ...;
 
 tuple Subtour { int size; int subtour[Rn]; }
{Subtour} subtours = ...;

 tuple Vsets { int size; int sommet; int voisins[Rn]; }
{Vsets} ensV = ...;

 dvar int s[Rn] in 0..1; 
 dvar int x[Rn][Rn] in 0..1;
 dvar int f[Rn][Rn]; 
 
 minimize sum(i in Rn) s[i];
 
subject to{
   
	// Existence des aretes
	forall (i in Rn, j in Rn)
		donnee: x[i][j] <= a[i][j];
 	  
	// Definition de s (degré sup à 3)
	forall (i in Rn)
		degre: (sum(j in Rn) a[i][j] - 2)*s[i] >= sum(j in Rn) (x[i][j] + x[j][i]) - 2;
	

	// Nombre d'aretes d'un arbre
	arbre: sum(i in Rn, j in Rn) x[i][j] == n - 1;
	
	// Existance des flots
	forall (i in Rn, j in Rn)
		flot: f[i][j] <= (n-1)*x[i][j];
	
	// Flot à la racine
	racine: sum(j in 2..n) f[1][j] == n - 1;
	
	// Conservation du flot
	forall (i in 2..n)
		concerv: sum(j in Rn: j != i) f[j][i] == sum(j in Rn) f[i][j] + 1;
	  
	// Connexité
	forall(i in 2..n)
	  connexe: sum(j in Rn) x[j][i] == 1;
	  
	// Inégalités valides 
	forall(i in 1..n, v in ensV: v.sommet == i)
		ineqdegre: (v.size - 2)*s[i] >= sum(j in Rn) v.voisins[j]*(x[i][j] + x[j][i]) - 2;
	
	
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

main{
	  var status = 0;
	  thisOplModel.generate();
	
	  var RC_EPS = 1.0e-6;
	
	  var masterDef = thisOplModel.modelDefinition;
	  var masterCplex = cplex;
	  var masterData = thisOplModel.dataElements;

	  var best;
	  var curr = Infinity;
	
	  while ( best != curr ) {
	    best = curr;
	
	    var masterOpl = new IloOplModel(masterDef, masterCplex);
	    masterOpl.addDataSource(masterData);
	    masterOpl.generate();
	    masterOpl.convertAllIntVars();
	        
	    writeln("Solve master.");
	    if ( masterCplex.solve() ) {
	      curr = masterCplex.getObjValue();
	      writeln();
	      writeln("OBJECTIVE: ",curr);
	    } 
	    else {
	      writeln("No solution!");
	      masterOpl.end();
	      break;
	    }
	
	    // Prepare the next iteration:
	    current_sol_x = masterOpl.x.solutionValue
	    current_sol_s = masterOpl.s.solutionValue
	    for (i in masterOpl.Rn){
		    var sizeV = 0
		    for (j in masterOpl.Rn){
		    	if (current_sol_x[i][j] + current_sol_x[j][i] > current_sol_s[i]){
			    	masterOpl.vois_essai[i][j] = 1;
			    	sizeV += 1;
     			}		    	
     			else{
     				masterOpl.vois_essai[i][j] = 0;
     			}
    		}
    		masterData.ensV.add(sizeV, i, masterOpl.vois_essai[i]);	    
   		}	    
   		
	    //masterOpl.end();
	  masterOpl.unconvertAllIntVars();
	  }
	  writeln("Relaxed model search end.");
	  
	  
	  var status = 0;
      var it =0;
	  while (1) {
        var cplex1 = new IloCplex();
        opl = new IloOplModel(masterDef,cplex1);
        opl.addDataSource(masterData);
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
        //writeln("Solution value : ", opl.x.solutionValue);

        if (opl.newSubtourSize == opl.n) {
          opl.end();
          cplex1.end();
          break; // not found
        }
        
        masterData.subtours.add(opl.newSubtourSize, opl.newSubtour);
        masterData.subtours.add(opl.newSubtourSize2, opl.newSubtour2);
		opl.end();
		cplex1.end();
    }

    status;
}

