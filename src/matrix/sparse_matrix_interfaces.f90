!==========================================================================!
!==========================================================================!
module sparse_matrix_interfaces                                            !
!==========================================================================!
!==========================================================================!
!====     This module contains the interface for matrices, which are a ====!
!==== sub-class of linear operators. Matrices have new methods for     ====!
!==== editing their entries; a general linear operator is immutable.   ====!
!====     There are many implementations of sparse matrices, depending ====!
!==== on the underlying connectivity graph.                            ====!
!====     o a default sparse matrix implementation uses no information ====!
!====       about the underlying graph type, only methods provided by  ====!
!====       the graph interface; however, it is sub-optimal for many   ====!
!====       operations, e.g. matrix-vector multiplication              ====!
!====     o other matrix formats (cs_matrix, ...) break encapsulation  ====!
!====       of the graphs they contain, but can execute performance-   ====!
!====       critical operations like matvec much faster                ====!
!==========================================================================!
!==========================================================================!


use types, only: dp
use linear_operator_interface
use graph_interfaces

implicit none




!--------------------------------------------------------------------------!
type, extends(linear_operator), abstract :: sparse_matrix_interface        !
!--------------------------------------------------------------------------!
    ! variables to tell which phases of initializing the matrix have
    ! already occurred
    logical :: dimensions_set = .false.
    logical :: graph_set = .false.

contains
    !--------------
    ! Constructors
    !--------------
    generic :: init => set_dimensions, setup
    ! Bind some of the initialization routines that follow to the same name

    procedure :: set_dimensions => set_sparse_matrix_dimensions
    ! Set the row and column dimension of a sparse matrix

    procedure :: setup => sparse_matrix_setup
    ! Set the row and column dimension of a sparse matrix and copy the
    ! connectivity structure from another graph

    procedure(sparse_mat_copy_graph_ifc), deferred :: copy_graph
    ! Initialize the matrix's connectivity structure as a copy of an
    ! input graph. The input graph need not be of the same format as the 
    ! matrix's graph

    procedure(sparse_mat_set_graph_ifc), deferred :: set_graph
    ! Given an input graph with the `target` attribute, check if that graph
    ! is of a type compatible with the invoking matrix. If so, make the
    ! matrix point to that graph; if not, throw an error.


    !-----------
    ! Accessors
    !-----------
    procedure(sparse_mat_get_nnz_ifc), deferred    :: get_nnz
    ! Return the number of non-zero entries of the matrix

    procedure(sparse_mat_get_degree_ifc), deferred :: get_row_degree
    procedure(sparse_mat_get_degree_ifc), deferred :: get_column_degree
    ! Return the number of non-zero entries in a given row/column

    procedure(sparse_mat_get_slice_ifc), deferred :: get_row
    procedure(sparse_mat_get_slice_ifc), deferred :: get_column
    ! Return all the indices of the non-zero entries in a given row/column
    ! and all the corresponding matrix entries


    !-----------------------
    ! Edge, value iterators
    !-----------------------
    procedure(sparse_mat_make_cursor_ifc), deferred :: make_cursor
    ! Make a cursor which stores some placeholder information needed for
    ! iterating through all the entries of a sparse matrix

    procedure(sparse_mat_get_edges_ifc), deferred :: get_edges
    ! Return a batch of edges of the underlying connectivity graph of the
    ! sparse matrix

    procedure(sparse_mat_get_entries_ifc), deferred :: get_entries
    ! Return a batch of edges of the connectivity graph of the sparse
    ! matrix, along with the corresponding matrix entries


    !----------
    ! Mutators
    !----------
    procedure(sparse_mat_set_value_ifc), deferred :: set_value
    ! Set the value of a matrix entry

    procedure(sparse_mat_set_value_ifc), deferred :: add_value
    ! Add a value to a matrix entry

    procedure :: set_multiple_values => sparse_mat_set_multiple_values
    procedure :: add_multiple_values => sparse_mat_add_multiple_values
    ! Set/add values to dense submatrices

    generic :: set => set_value, set_multiple_values
    generic :: add => add_value, add_multiple_values
    ! Generics for each of the mutators

    procedure(sparse_mat_zero_ifc), deferred :: zero
    ! Zero out all matrix entries

    procedure(sparse_mat_permute_ifc), deferred :: left_permute
    ! Permute the rows of a matrix

    procedure(sparse_mat_permute_ifc), deferred :: right_permute
    ! Permute the columns of a matrix


    !------------------------------
    ! Matrix-vector multiplication
    !------------------------------
    ! Note: if you want performance, you had best override these.
    procedure :: matvec_add   => sparse_matrix_matvec_add
    ! Add the product A*x to the vector y

    procedure :: matvec_t_add => sparse_matrix_matvec_t_add
    ! Add the product transpose(A)*x to the vector y


    !-------------
    ! Destructors
    !-------------
    procedure(sparse_mat_destroy_ifc), deferred :: destroy
    ! Deallocate the contents of the matrix and nullify any pointers


    !--------------
    ! Optimization
    !--------------
    procedure :: is_get_row_fast => get_slice_is_not_fast
    procedure :: is_get_column_fast => get_slice_is_not_fast
    ! Returns true if the matrix can return an entire row / column in O(d)
    ! time/space, where `d` is the maximum degree of a row / column
    ! respectively. By default it is assumed that getting a slice is not
    ! fast, but implementations (e.g. ellpack, CSC) can override either
    ! in case it is a fast operation.
    ! The speed of getting a slice may well be state-dependent, e.g. a
    ! default_matrix could be slow if the underlying graph is in COO format
    ! but could become fast if its storage is converted to CSR.


    !-------------------------
    ! Testing, debugging, I/O
    !-------------------------
    procedure :: to_dense_matrix => sparse_matrix_to_dense_matrix
    ! Convert the sparse matrix to an equivalent dense matrix

    procedure :: to_file => sparse_matrix_to_file
    ! Write out all the entries of the sparse matrix to a file


end type sparse_matrix_interface



!--------------------------------------------------------------------------!
abstract interface                                                         !
!--------------------------------------------------------------------------!
    subroutine sparse_mat_copy_graph_ifc(A, g)
        import :: graph_interface, sparse_matrix_interface
        class(sparse_matrix_interface), intent(inout) :: A
        class(graph_interface), intent(in) :: g
    end subroutine sparse_mat_copy_graph_ifc

    subroutine sparse_mat_set_graph_ifc(A, g)
        import :: graph_interface, sparse_matrix_interface
        class(sparse_matrix_interface), intent(inout) :: A
        class(graph_interface), target, intent(in) :: g
    end subroutine sparse_mat_set_graph_ifc

    function sparse_mat_get_nnz_ifc(A) result(nnz)
        import :: sparse_matrix_interface
        class(sparse_matrix_interface), intent(in) :: A
        integer :: nnz
    end function sparse_mat_get_nnz_ifc

    function sparse_mat_get_degree_ifc(A, k) result(d)
        import :: sparse_matrix_interface
        class(sparse_matrix_interface), intent(in) :: A
        integer, intent(in) :: k
        integer :: d
    end function sparse_mat_get_degree_ifc

    subroutine sparse_mat_get_slice_ifc(A, nodes, slice, k)
        import :: sparse_matrix_interface, dp
        class(sparse_matrix_interface), intent(in) :: A
        integer, intent(out) :: nodes(:)
        real(dp), intent(out) :: slice(:)
        integer, intent(in) :: k
    end subroutine sparse_mat_get_slice_ifc

    function sparse_mat_make_cursor_ifc(A) result(cursor)
        import :: sparse_matrix_interface, graph_edge_cursor
        class(sparse_matrix_interface), intent(in) :: A
        type(graph_edge_cursor) :: cursor
    end function sparse_mat_make_cursor_ifc

    subroutine sparse_mat_get_edges_ifc(A, edges, cursor, &
                                                & num_edges, num_returned)
        import :: sparse_matrix_interface, graph_edge_cursor
        class(sparse_matrix_interface), intent(in) :: A
        integer, intent(in) :: num_edges
        integer, intent(out) :: edges(2, num_edges)
        type(graph_edge_cursor), intent(inout) :: cursor
        integer, intent(out) :: num_returned
    end subroutine sparse_mat_get_edges_ifc

    subroutine sparse_mat_get_entries_ifc(A, edges, entries, cursor, &
                                                & num_edges, num_returned)
        import :: sparse_matrix_interface, dp, graph_edge_cursor
        class(sparse_matrix_interface), intent(in) :: A
        integer, intent(in) :: num_edges
        integer, intent(out) :: edges(2, num_edges)
        real(dp), intent(out) :: entries(num_edges)
        type(graph_edge_cursor), intent(inout) :: cursor
        integer, intent(out) :: num_returned
    end subroutine sparse_mat_get_entries_ifc

    subroutine sparse_mat_set_value_ifc(A, i, j, z)
        import :: sparse_matrix_interface, dp
        class(sparse_matrix_interface), intent(inout) :: A
        integer, intent(in) :: i, j
        real(dp), intent(in) :: z
    end subroutine sparse_mat_set_value_ifc

    subroutine sparse_mat_zero_ifc(A)
        import :: sparse_matrix_interface
        class(sparse_matrix_interface), intent(inout) :: A
    end subroutine sparse_mat_zero_ifc

    subroutine sparse_mat_permute_ifc(A, p)
        import :: sparse_matrix_interface
        class(sparse_matrix_interface), intent(inout) :: A
        integer, intent(in) :: p(:)
    end subroutine sparse_mat_permute_ifc

    subroutine sparse_mat_destroy_ifc(A)
        import :: sparse_matrix_interface
        class(sparse_matrix_interface), intent(inout) :: A
    end subroutine sparse_mat_destroy_ifc

end interface




contains




!==========================================================================!
!==== Constructors                                                     ====!
!==========================================================================!

!--------------------------------------------------------------------------!
subroutine sparse_matrix_setup(A, nrow, ncol, g)                           !
!--------------------------------------------------------------------------!
    class(sparse_matrix_interface), intent(inout) :: A
    integer, intent(in) :: nrow, ncol
    class(graph_interface), intent(in) :: g

    call A%set_dimensions(nrow, ncol)
    call A%copy_graph(g)

end subroutine sparse_matrix_setup



!--------------------------------------------------------------------------!
subroutine set_sparse_matrix_dimensions(A, nrow, ncol)                     !
!--------------------------------------------------------------------------!
    class(sparse_matrix_interface), intent(inout) :: A
    integer, intent(in) :: nrow, ncol

    A%nrow = nrow
    A%ncol = ncol

    A%dimensions_set = .true.

    call A%add_reference()

end subroutine set_sparse_matrix_dimensions




!==========================================================================!
!==== Mutators                                                         ====!
!==========================================================================!

!--------------------------------------------------------------------------!
subroutine sparse_mat_set_multiple_values(A, is, js, B)                    !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(inout) :: A
    integer, intent(in) :: is(:), js(:)
    real(dp), intent(in) :: B(:,:)
    ! local variables
    integer :: i, j, k, l
    real(dp) :: z

    do l = 1, size(js)
        j = js(l)

        do k = 1, size(is)
            i = is(k)
            z = B(k, l)

            call A%set_value(i, j, z)
        enddo
    enddo

end subroutine sparse_mat_set_multiple_values



!--------------------------------------------------------------------------!
subroutine sparse_mat_add_multiple_values(A, is, js, B)                    !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(inout) :: A
    integer, intent(in) :: is(:), js(:)
    real(dp), intent(in) :: B(:,:)
    ! local variables
    integer :: i, j, k, l
    real(dp) :: z

    do l = 1, size(js)
        j = js(l)

        do k = 1, size(is)
            i = is(k)
            z = B(k, l)

            call A%add_value(i, j, z)
        enddo
    enddo

end subroutine sparse_mat_add_multiple_values




!==========================================================================!
!==== Matrix-vector multiplication                                     ====!
!==========================================================================!

!--------------------------------------------------------------------------!
subroutine sparse_matrix_matvec_add(A, x, y)                               !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(in) :: A
    real(dp), intent(in)    :: x(:)
    real(dp), intent(inout) :: y(:)
    ! local variables
    integer :: i, j, k
    integer :: num_returned, edges(2, batch_size)
    real(dp) :: vals(batch_size)
    type(graph_edge_cursor) :: cursor

    cursor = A%make_cursor()
    do while (.not. cursor%done())
        call A%get_entries(edges, vals, cursor, batch_size, num_returned)

        do k = 1, num_returned
            i = edges(1, k)
            j = edges(2, k)

            y(i) = y(i) + vals(k) * x(j)
        enddo
    enddo

end subroutine sparse_matrix_matvec_add



!--------------------------------------------------------------------------!
subroutine sparse_matrix_matvec_t_add(A, x, y)                             !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(in) :: A
    real(dp), intent(in)    :: x(:)
    real(dp), intent(inout) :: y(:)
    ! local variables
    integer :: i, j, k
    integer :: num_returned, edges(2, batch_size)
    real(dp) :: vals(batch_size)
    type(graph_edge_cursor) :: cursor

    cursor = A%make_cursor()
    do while (.not. cursor%done())
        call A%get_entries(edges, vals, cursor, batch_size, num_returned)

        do k = 1, num_returned
            i = edges(2, k)
            j = edges(1, k)

            y(i) = y(i) + vals(k) * x(j)
        enddo
    enddo

end subroutine sparse_matrix_matvec_t_add




!==========================================================================!
!==== Optimization                                                     ====!
!==========================================================================!

!--------------------------------------------------------------------------!
function get_slice_is_not_fast(A) result(fast)                             !
!--------------------------------------------------------------------------!
    class(sparse_matrix_interface), intent(in) :: A
    logical :: fast

    fast = .false.

end function get_slice_is_not_fast




!==========================================================================!
!==== Testing, debugging, I/O                                          ====!
!==========================================================================!

!--------------------------------------------------------------------------!
subroutine sparse_matrix_to_dense_matrix(A, B, trans)                      !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(in) :: A
    real(dp), intent(out) :: B(:,:)
    logical, intent(in), optional :: trans
    ! local variables
    integer :: i, j, k, ord(2)
    integer :: num_returned, edges(2, batch_size)
    type(graph_edge_cursor) :: cursor
    real(dp) :: vals(batch_size)

    ! Set the dense matrix to 0
    B = 0.0_dp

    ! If we're actually making the transpose of A, set the variable ord
    ! accordingly
    ord = [1, 2]
    if (present(trans)) then
        if (trans) ord = [2, 1]
    endif

    ! Get a cursor for iterating through the matrix entries and find how
    ! many batches it will take
    cursor = A%make_cursor()
    do while (.not. cursor%done())
        ! Get a batch of entries from A
        call A%get_entries(edges, vals, cursor, batch_size, num_returned)

        do k = 1, num_returned
            ! For each edge in the batch,
            i = edges(ord(1), k)
            j = edges(ord(2), k)

            ! Set the corresponding entry in the output matrix `B`
            ! NOTE: In some graph formats (e.g. COO, ellpack), more than
            ! one copy of an edge can be stored in the graph.
            ! With that in mind, we have to *add* contributions to each
            ! entry of `B`, not set them. Depending on the order in which
            ! the entries were added to `B`, we could set it to the true
            ! value and then re-set it to zero later. By adding up all
            ! contributions, we avoid that possibility.
            B(i, j) = B(i, j) + vals(k)
        enddo
    enddo

end subroutine sparse_matrix_to_dense_matrix



!--------------------------------------------------------------------------!
subroutine sparse_matrix_to_file(A, filename, trans)                       !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(sparse_matrix_interface), intent(in) :: A
    character(len=*), intent(in) :: filename
    logical, intent(in), optional :: trans
    ! local variables
    integer :: i, j, k, ord(2), nv(2)
    integer :: num_returned, edges(2, batch_size)
    type(graph_edge_cursor) :: cursor
    real(dp) :: vals(batch_size)

    ! If we're actually writing the transpose of the matrix, set the
    ! variable ord accordingly and the dimensions of the matrix that
    ! we're writing out
    ord = [1, 2]
    nv = [A%nrow, A%ncol]
    if (present(trans)) then
        if (trans) then
            ord = [2, 1]
            nv = [A%ncol, A%nrow]
        endif
    endif

    !TODO make sure it's a safe unit number to use somehow
    ! Open the file
    open(unit = 10, file = trim(filename))

    ! Write out the dimensions of the matrix and the number of non-zero
    ! entries
    write(10,*) nv(1), nv(2), A%get_nnz()

    ! Get a cursor for iterating through the matrix entries and find how
    ! many batches it will take
    cursor = A%make_cursor()
    do while (.not. cursor%done())
        ! Get a batch of entries from A
        call A%get_entries(edges, vals, cursor, batch_size, num_returned)

        do k = 1, num_returned
            ! For each edge in the batch, 
            i = edges(ord(1), k)
            j = edges(ord(2), k)

            ! Write out the edge and the corresponding matrix entry
            write(10, *) i, j, vals(k)
        enddo
    enddo

    ! Close the file
    close(10)

end subroutine sparse_matrix_to_file




end module sparse_matrix_interfaces

