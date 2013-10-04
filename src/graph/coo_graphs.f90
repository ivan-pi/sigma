module coo_graphs

use graphs
use types, only: dynamic_array

implicit none



!--------------------------------------------------------------------------!
type, extends(graph) :: coo_graph                                          !
!--------------------------------------------------------------------------!
    type(dynamic_array) :: edges(2)
    integer, allocatable :: degree(:)
contains
    procedure :: init => coo_init
    procedure :: neighbors => coo_neighbors
    procedure :: connected => coo_connected
    procedure :: find_edge => coo_find_edge
    procedure :: add_edge => coo_add_edge
    procedure :: delete_edge => coo_delete_edge
    procedure :: left_permute => coo_graph_left_permute
    procedure :: right_permute => coo_graph_right_permute
    procedure :: free => coo_free
    procedure :: dump_edges => coo_dump_edges

end type coo_graph





contains



!--------------------------------------------------------------------------!
subroutine coo_init(g,n,m,edges)                                           !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: n
    integer, intent(in), optional :: m, edges(:,:)
    ! local variables
    integer :: i,k,ne

    g%n = n
    allocate(g%degree(n))

    if (present(m)) then
        g%m = m
    else
        g%m = n
    endif

    if (present(edges)) then
        ne = size(edges,2)
        g%ne = ne

        g%degree = 0
        do k=1,ne
            i = edges(1,k)
            g%degree(i) = g%degree(i)+1
        enddo
        g%max_degree = maxval(g%degree)
    else
        ne = 0
        g%ne = ne
        g%max_degree = 0
    endif

    call g%edges(1)%init()
    call g%edges(2)%init()

    if (present(edges)) then
        do k=1,ne
            call g%edges(1)%push( edges(1,k) )
            call g%edges(2)%push( edges(2,k) )
        enddo
    endif
    
end subroutine coo_init



!--------------------------------------------------------------------------!
subroutine coo_neighbors(g,i,nbrs)                                         !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i
    integer, intent(out) :: nbrs(:)
    ! local variables
    integer :: k,next

    nbrs = 0
    next = 0
    do k=1,g%ne
        if (g%edges(1)%get_entry(k)==i) then
            next = next+1
            nbrs(next) = g%edges(2)%get_entry(k)
        endif
    enddo

end subroutine coo_neighbors



!--------------------------------------------------------------------------!
function coo_connected(g,i,j)                                              !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i,j
    logical :: coo_connected
    ! local variables
    integer :: k

    coo_connected = .false.

    do k=1,g%ne
        if (g%edges(1)%get_entry(k)==i.and.g%edges(2)%get_entry(k)==j) then
            coo_connected = .true.
        endif
    enddo

end function coo_connected



!--------------------------------------------------------------------------!
function coo_find_edge(g,i,j)                                              !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i,j
    integer :: coo_find_edge
    ! local variables
    integer :: k

    coo_find_edge = -1

    do k=1,g%ne
        if (g%edges(1)%get_entry(k)==i.and.g%edges(2)%get_entry(k)==j) then
            coo_find_edge = k
        endif
    enddo

end function coo_find_edge



!--------------------------------------------------------------------------!
subroutine coo_add_edge(g,i,j)                                             !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: i,j
    ! local variables
    integer :: k

    if (.not.g%connected(i,j)) then
        ! Add in the new edge
        call g%edges(1)%push(i)
        call g%edges(2)%push(j)

        ! Increase the number of edges
        g%ne = g%ne+1

        ! If the degree of node i is now the greatest of all nodes in the
        ! graph, update the degree accordingly
        g%degree(i) = g%degree(i)+1
        if (g%degree(i) > g%max_degree) g%max_degree = g%degree(i)
    endif

end subroutine coo_add_edge



!--------------------------------------------------------------------------!
subroutine coo_delete_edge(g,i,j)                                          !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: i,j
    ! local variables
    integer :: k,l,it,jt

    k = g%find_edge(i,j)

    if (k/=-1) then
        it = g%edges(1)%pop()
        jt = g%edges(2)%pop()

        if (k<g%ne) then
            call g%edges(1)%set_entry(k,it)
            call g%edges(2)%set_entry(k,jt)
        endif

        ! Decrement the number of edges
        g%ne = g%ne-1

        ! Evaluate the graph's new maximum degree
        g%degree(i) = g%degree(i)-1
        if (g%degree(i)+1==g%max_degree) g%max_degree = maxval(g%degree)
    endif

end subroutine coo_delete_edge



!--------------------------------------------------------------------------!
subroutine coo_graph_left_permute(g,p)                                     !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: p(:)
    ! local variables
    integer :: k

    do k=1,g%ne
        call g%edges(1)%set_entry(k,p(g%edges(1)%get_entry(k)))
    enddo

end subroutine coo_graph_left_permute



!--------------------------------------------------------------------------!
subroutine coo_graph_right_permute(g,p)                                    !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: p(:)
    ! local variables
    integer :: k

    do k=1,g%ne
        call g%edges(2)%set_entry(k,p(g%edges(2)%get_entry(k)))
    enddo

end subroutine coo_graph_right_permute



!--------------------------------------------------------------------------!
subroutine coo_free(g)                                                     !
!--------------------------------------------------------------------------!
    class(coo_graph), intent(inout) :: g

    deallocate(g%edges(1)%array,g%edges(2)%array)

    g%n = 0
    g%m = 0
    g%ne = 0
    g%max_degree = 0

end subroutine coo_free



!--------------------------------------------------------------------------!
subroutine coo_dump_edges(g,edges)                                         !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(out) :: edges(:,:)
    ! local variables
    integer :: k

    do k=1,g%ne
        edges(1,k) = g%edges(1)%get_entry(k)
        edges(2,k) = g%edges(2)%get_entry(k)
    enddo

end subroutine coo_dump_edges



end module coo_graphs
