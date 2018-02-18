/*********************************************
 * OPL 12.5 Model
 * Author: seb
 * Creation Date: 18 févr. 2018 at 18:48:48
 *********************************************/

 int n = ...;
 range Rn = 1..n;
 int a[Rn][Rn] = ...;

 dvar boolean s[Rn]; 
 dvar boolean x[Rn][Rn];
 dvar int y[Rn]; 
 
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
	
	// Numérotation de la racine
	racine: y[1] == 0;
	
	// Numérotation des sommets dans l'ordre croissant
	forall (i in Rn, j in Rn)
	  ordre: y[i] - y[j] + 1 <= n*(1 - x[i][j]);
	  
	// Connexité
	forall(i in 2..n)
	  connexe: sum(j in Rn) x[j][i] == 1;
};

