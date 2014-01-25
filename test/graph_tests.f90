program graph_tests

use fempack

implicit none

    ! variables for testing correctness of graph operations
    class(graph), allocatable :: g
    integer :: i,j,k,l,n,test
    integer, allocatable :: edges(:,:), nbrs(:), p(:)
    logical :: correct
    ! variables for testing graph edge iterator
    type(graph_edge_cursor) :: cursor
    integer, allocatable :: reference_edges(:,:)
    integer :: num_blocks,num_returned
    logical, allocatable :: found_by_iterator(:)
    ! command-line arguments
    character(len=16) :: arg
    logical :: verbose

    verbose = .false.
    call getarg(1,arg)
    if (trim(arg)=="-v" .or. trim(arg)=="--verbose") then
        verbose = .true.
    endif

    allocate(edges(2,12),found_by_iterator(24),reference_edges(2,24))

    reference_edges(1,1:6) = 1
    reference_edges(2,1:6) = [2,3,4,5,6,7]
    reference_edges(1,7:9) = 2
    reference_edges(2,7:9) = [1,3,7]
    reference_edges(1,10:12) = 3
    reference_edges(2,10:12) = [1,2,4]
    reference_edges(1,13:15) = 4
    reference_edges(2,13:15) = [1,3,5]
    reference_edges(1,16:18) = 5
    reference_edges(2,16:18) = [1,4,6]
    reference_edges(1,19:21) = 6
    reference_edges(2,19:21) = [1,5,7]
    reference_edges(1,22:24) = 7
    reference_edges(2,22:24) = [1,6,2]


    !----------------------------------------------------------------------!
    ! Loop through and test each graph type                                !
    !----------------------------------------------------------------------!
    do test=1,4
        ! Allocate the graph
        select case(test)
            case(1)
                allocate(ll_graph::g)
                if (verbose) print *, 'Test 1, linked-list graph'
            case(2)
                allocate(coo_graph::g)
                if (verbose) print *, 'Test 2, coordinate graph'
            case(3)
                allocate(cs_graph::g)
                if (verbose) print *, 'Test 3, compressed sparse graph'
            case(4)
                allocate(ellpack_graph::g)
                if (verbose) print *, 'Test 4, ellpack graph'
        end select

        ! Initialize the graph with a set of pre-defined edges
        call g%init(7,7,[6,3,3,3,3,3,3])

        ! Check that the initialization routine has correctly entered the
        ! capacity of the graph
        if (g%capacity < 24) then
            print *, 'Graph capacity should be >= 24'
            print *, 'Value found:',g%capacity
            print *, test
            call exit(1)
        endif

        if (g%ne/=0) then
            print *, 'Number of graph edges at initialization should = 0'
            print *, 'Value found:',g%ne
            print *, test
            call exit(1)
        endif

        do i=1,6
            call g%add_edge(i,i+1)
            call g%add_edge(1,i+1)
        enddo
        call g%add_edge(7,2)

        ! Check that the graph has the right number of edges now
        if (g%ne/=12) then
            print *, 'Number of graph edges after insertion should be 12'
            print *, 'Value found:',g%ne
            print *, test
            call exit(1)
        endif

        ! Check that edge 1 has been connected to edge 2 but that edge 2
        ! is not connected to edge 1
        if (.not.g%connected(1,2) .or. g%connected(2,1)) then
            print *, 'Graph should have 1 -> 2, 2 -/> 1; we have:'
            if (.not.g%connected(1,2)) then
                print *, ' 1 -/> 2'
            else
                print *, ' 2 -> 1'
            endif
            print *, test
            call exit(1)
        endif

        ! Check that the maximum degree of the graph has been calculated
        ! properly by the initialization routine
        if (g%max_degree/=6) then
            print *, 'Max degree of g should be 6; it is:',g%max_degree
            print *, test
            call exit(1)
        endif

        ! Add in new edges to symmetrize the graph
        do i=1,6
            call g%add_edge(i+1,i)
            call g%add_edge(i+1,1)
        enddo
        call g%add_edge(2,7)

        ! Check that edge 1 is still connected to edge 2 and that edge 2
        ! is now connected to edge 1
        if (.not.g%connected(1,2) .or. .not.g%connected(2,1)) then
            print *, 'Supposed to have 1 -> 2 and 2 -> 1'
            print *, test
            call exit(1)
        endif

        ! Check that the total number of edges has been properly updated
        if (g%ne/=24) then
            print *, '12 edges were added; graph should have 24 edges'
            print *, 'Graph has ',g%ne,' edges'
            print *, test
            call exit(1)
        endif

        allocate(nbrs(g%max_degree))

        ! Check that finding all neighbors of a given edge works
        call g%neighbors(1,nbrs)
        correct = .true.
        do i=1,g%max_degree
            if (nbrs(i)/=i+1) correct = .false.
        enddo
        if (.not.correct) then
            print *, 'Node 1 should neighbor all other nodes'
            call exit(1)
            print *, test
        endif

        ! Check that iterating through a graph's edges works
        if (verbose) print *, '    Edge iterator output:'
        cursor = g%make_cursor(0)
        num_blocks = (cursor%final-cursor%start)/12+1
        found_by_iterator = .false.
        do n=1,num_blocks
            edges = g%get_edges(cursor,12,num_returned)

            if (verbose) then
                print *, edges(1,:)
                print *, edges(2,:)
            endif

            do k=1,12
                i = edges(1,k)
                j = edges(2,k)

                do l=1,24
                    if (reference_edges(1,l)==i .and. &
                            & reference_edges(2,l)==j) then
                        found_by_iterator(l) = .true.
                    endif
                enddo
            enddo
        enddo

        correct = .true.
        do k=1,24
            correct = correct .and. found_by_iterator(k)
        enddo

        if (.not.correct) then
            print *, 'Not all edges found by iterator'
            do k=1,24
                if (.not.found_by_iterator(k)) then
                    i = reference_edges(1,k)
                    j = reference_edges(2,k)
                    print *, 'Missing edge:',i,j
                endif
            enddo
            call exit(1)
        endif

        ! Check that permutation works properly
        !allocate(p(7))
        !do i=1,7
        !    p(i) = i-1
        !enddo
        !p(1) = 7
        !call g%right_permute(p)
        !call g%left_permute(p)
        !deallocate(p)

        ! Delete all connections between node 1 and any even nodes
        do i=2,6,2
            call g%delete_edge(1,i)
            call g%delete_edge(i,1)
        enddo

        ! Check that edge deletion worked properly
        do i=2,6,2
            if (g%connected(1,i) .or. g%connected(i,1)) then
                print *, 'Test',test
                print *, 'All connections between 1 and even nodes were '
                print *, 'deleted, and yet 1 is still connected '
                print *, 'to node ',i
                call exit(1)
            endif
        enddo

        if (g%max_degree/=3) then
            print *, 'Test',test
            print *, 'Max degree was not properly decremented;'
            print *, 'should be 3, value found:',g%max_degree
        endif

        call g%free()

        deallocate(g,nbrs)

        if (verbose) print *, ' '

    enddo




end program graph_tests
