;; misc.
(define square
  (lambda (x)
    (* x x)))

(define dist
  (lambda (u v)
    (do ((i (1- (vector-length u)) (1- i))
	 (d 0 (+ d (square (- (vector-ref u i) (vector-ref v i))))))
	((< i 0) (sqrt d)))))

(define v:<
  (lambda (u v)
    (let ((n (vector-length u)))
      (let loop ((i 0))
	(if (< i n)
	    (let ((ui (vector-ref u i))
		  (vi (vector-ref v i)))
	      (or (and (= ui vi) (loop (1+ i)))
		  (< ui vi))))))))

(define-record-type %kd
  (fields root
	  L
	  R
	  dim
	  size))

(define empty?
  (lambda (tree)
    (eq? tree 'empty)))

(define leaf?
  (lambda (tree)
    (not (or (%kd? tree)
	     (empty? tree)))))

(define size
  (lambda (tree)
    (cond ((%kd? tree) (%kd-size tree))
	  ((leaf? tree) 1)
	  (else 0 0))))

(define join
  (lambda (root L R axis)
    (if (and (empty? L)
	     (empty? R))
	root
	(make-%kd root L R axis (+ 1 (size L) (size R))))))

(define root
  (lambda (tree)
    (if (%kd? tree)
	(%kd-root tree)
	(and (not (empty? tree))
	     tree))))

(define right
  (lambda (tree)
    (%kd-R tree)))

(define left
  (lambda (tree)
    (%kd-L tree)))

(define build
  (lambda (points k d n)
    (cond ((= n 0) 'empty)
	  ((= n 1) (car points))
	  (else (let* ((pts (sort (lambda (u v)
				    (< (vector-ref (car u) k)
				       (vector-ref (car v) k)))
				  points))
		       (a (quotient (1- n) 2))
		       (ls (list-head pts a))
		       (rs (list-tail pts a))
		       (k* (mod (1+ k) d)))
		  (join (car rs)
			(build ls k* d a)
			(build (cdr rs) k* d (- n a 1))
			k))))))

(define closed-nhood
  (lambda (tree v radius)
    (letrec ((d (vector-length v))
	     (query (lambda (tree k)
		      (cond ((empty? tree) '())
			    ((%kd? tree)
			     (let* ((r (root tree))
				    (rk (vector-ref (car r) k))
				    (vk (vector-ref v k))
				    (dk (- vk rk))
				    (k* (mod (1+ k) d))
				    (L (left tree))
				    (R (right tree)))
			       (cond ((> dk radius) (query R k*))
				     ((> (- dk) radius) (query L k*))
				     (else `(,@(query L k*)
					     ,@(query r k*)
					     ,@(query R k*))))))
			    (else
			     (if (<= (dist v (car tree))
				     radius)
				 `(,tree)
				 '()))))))
      (query tree 0))))

(define open-nhood
  (lambda (tree v radius)
    (letrec ((d (vector-length v))
	     (query (lambda (tree k)
		      (cond ((empty? tree) '())
			    ((%kd? tree)
			     (let* ((r (root tree))
				    (rk (vector-ref (car r) k))
				    (vk (vector-ref v k))
				    (dk (- vk rk))
				    (k* (mod (1+ k) d))
				    (L (left tree))
				    (R (right tree)))
			       (cond ((>= dk radius) (query R k*))
				     ((>= (- dk) radius) (query L k*))
				     (else `(,@(query L k*)
					     ,@(query r k*)
					     ,@(query R k*))))))
			    (else
			     (if (< (dist v (car tree))
				    radius)
				 `(,tree)
				 '()))))))
      (query tree 0))))

(define nearest-neighbor
  (lambda (tree v)
    (letrec ((d (vector-length v))
	     (w #f)
	     (x +inf.0)
	     (query (lambda (tree k)
		      (unless (empty? tree)
			(if (%kd? tree)
			    (let* ((r (root tree))
				   (rk (vector-ref (car r) k))
				   (vk (vector-ref v k))
				   (dk (- vk rk))
				   (k* (mod (1+ k) d))
				   (L (left tree))
				   (R (right tree)))
			      (query r k*)
			      (when (and (<= 0 dk) (<= dk x))
				(query R k*))
			      (when (and (<= dk 0) (<= (- dk) x))
				(query L k*)))
			    (let* ((r (car tree))
				   (y (dist v r)))
			      (when (and (< y x) (not (= y 0)))
				(set! x y)
				(set! w r))))))))
      (and (not (empty? tree))
	   (begin
	     (query tree 0)
	     w)))))

(define nearest-node
  (lambda (tree v)
    (letrec ((d (vector-length v))
	     (w #f)
	     (x +inf.0)
	     (query (lambda (tree k)
		      (unless (empty? tree)
			(if (%kd? tree)
			    (let* ((r (root tree))
				   (rk (vector-ref (car r) k))
				   (vk (vector-ref v k))
				   (dk (- vk rk))
				   (k* (mod (1+ k) d))
				   (L (left tree))
				   (R (right tree)))
			      (query r k*)
			      (when (and (<= 0 dk) (<= dk x))
				(query R k*))
			      (when (and (<= dk 0) (<= (- dk) x))
				(query L k*)))
			    (let* ((r (car tree))
				   (y (dist v r)))
			      (when (< y x)
				(set! x y)
				(set! w r))))))))
      (and (not (empty? tree))
	   (begin
	     (query tree 0)
	     w)))))

(define lookup
  (lambda (tree v)
    (letrec ((d (vector-length v))
	     (query (lambda (tree k)
		      (and (not (empty? tree))
			   (if (%kd? tree)
			       (let* ((r (root tree))
				      (rk (vector-ref (car r) k))
				      (vk (vector-ref v k))
				      (k* (mod (1+ k) d))
				      (L (left tree))
				      (R (right tree)))
				 (cond ((> vk rk) (query R k*))
				       ((< vk rk) (query L k*))
				       (else (or (and (equal? (car r) v) r)
						 (query R k*)
						 (query L k*)))))
			       (and (equal? (car tree) v)
				    tree))))))
      (query tree 0))))

(define max-in-dimension
  (lambda (tree dim)
    (and (not (empty? tree))
	 (letrec ((m (car (tree-root tree)))
		  (d (vector-length m))
		  (aux (lambda (tree k)
			 #f
			 )))
	   (aux (left tree) 0)
	   (aux (right tree) 0)))))

(define insert
  (lambda (tree v x)
    (letrec ((d (vector-length v))
	     (aux (lambda (tree k)
		    (cond ((empty? tree) (cons v x))
			  ((%kd? tree)
			   (let* ((rt (%kd-root tree))
				  (r (car rt))
				  (vk (vector-ref v k))
				  (rk (vector-ref r k))
				  (k* (mod (1+ k) d))
				  (R (%kd-R tree))
				  (L (%kd-L tree)))
			     (cond ((and (= vk rk) (equal? v r))
				    (join (cons v x) L R k))
				   ((or (< vk rk)
					(and (= vk rk) (v:< v r)))
				    (join rt (aux L k*) R k))
				   (else (join rt L (aux R k*) k)))))
			  (else
			   (let* ((r (car tree))
				  (vk (vector-ref v k))
				  (rk (vector-ref r k))
				  (k* (mod (1+ k) d))
				  (t* (cons v x)))
			     (cond ((and (= vk rk) (equal? v r)) t*)
				   ((< vk rk) (join tree t* 'empty k))
				   (else (join tree 'empty t* k)))))))))
      (aux tree 0))))

(define delete
  (lambda (tree v)
    (letrec ((d (vector-length v))
	     (aux (lambda (tree k)
		    (cond ((empty? tree) tree)
			  ((leaf? tree)
			   (or (and (equal? (car tree) v) empty)
			       tree))
			  (else
			   ;; tricky case is if root is vertex to be deleted;
			   ;; propsal: find nearest neighbor and delete that from subtree,
			   ;; recombine with that at root?
			   
			   ;; unsatisfying proposal: if this is the case, just rebuild the tree
			   ;; from this dimension ....

			   ;; another one:
			   ;; keep track of size?
			   ;; delete min from right or max form left by a given dimension and
			   ;; set that to root
			   (let* ((r (car (root tree)))
				  (vk (vector-ref v k))
				  (rk (vector-ref r k))
				  (k* (mod (1+ k) d)))
			     (cond ((and (= vk rk) (equal? v r))
				    (node k (cons v x)
					  (left tree)
					  (right tree)))
				   ((or (< vk rk)
					(and (= vk rk) (v:< v r)))
				    (node k (root tree)
					  (aux (left tree) k*)
					  (right tree)))
				   (else
				    (node k (root tree)
					  (left tree)
					  (aux (right tree) k*))))))))))
      (aux tree 0))))

(define tree->alist
  (lambda (tree)
    (letrec ((aux (lambda (tree)
		    (cond ((%kd? tree)
			   `(,@(aux (%kd-L tree))
			     ,(root tree)
			     ,@(aux (%kd-R tree))))
			  ((empty? tree) '())
			  (else `(,tree)))
		    )))
      (aux tree))))

(define tree->keys
  (lambda (tree)
    (letrec ((aux (lambda (tree)
		    (cond ((%kd? tree)
			   `(,@(aux (%kd-L tree))
			     ,(car (root tree))
			     ,@(aux (%kd-R tree))))
			  ((empty? tree) '())
			  (else `(,(car tree))))
		    )))
      (aux tree))))

(define tree-map
  (lambda (g tree)
    (letrec ((aux (lambda (tree)
		    (cond ((%kd? tree)
			   (make-%kd (aux (%kd-root tree))
				     (aux (%kd-L tree))
				     (aux (%kd-R tree))
				     (%kd-dim tree)
				     (%kd-size tree)))
			  ((empty? tree) tree)
			  (else (cons (car tree)
				      (g (cdr tree))))))))
      (aux tree))))

(define kd-tree ;; points assumed to be list of key val pairs
  (lambda (points)
    (cond ((null? points) 'empty)
	  (else
	   (when (or (not (pair? (car points)))
		     (not (vector? (caar points))))
	     (error 'kd-tree
		    "input not a list of key value pairs. keys should be vectors"
		    points))
	   (let ((d (vector-length (caar points))))
	     (build points 0 d (length points)))))))

