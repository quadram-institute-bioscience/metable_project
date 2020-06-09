-- INSERT INTO metable_genomes (id, owner, ps,size) VALUES
--		 ("30286", "METABLE", PS0000, 3819434)

-- INSERT INTO metable_genes (genome, type, contig, start, end, strand, prokka, ec, gene, inference, locus_tag, product)
-- 		 VALUES ("30286","CDS", "ctg_1", "3966", "4706", TRUE,"PROKKA_00005", "3.5.1.-", "pdaC_1", "ab initio prediction:Prodigal:2.6,similar to AA sequence:UniProtKB:O34798", "PROKKA_00005", "Peptidoglycan-N-acetylmuramic acid deacetylase PdaC");
CREATE TABLE metable_genomes (
	id	     INT PRIMARY KEY,
	owner    VARCHAR(122),
	ps       VARCHAR(40),
	size     INT
);

CREATE TABLE metable_genes (
	genome    INT,
	type	  VARCHAR(20),
	contig	  VARCHAR(20),
	start	  INT,
	end		  INT,
	strand	  INT,
	prokka    VARCHAR(100),
	ec        VARCHAR(40),
	gene      VARCHAR(40),
	inference VARCHAR(255),
	locus_tag VARCHAR(40),
	product	  VARCHAR(255)

);