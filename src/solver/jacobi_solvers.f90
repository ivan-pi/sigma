module jacobi_solvers

use types, only: dp
use linear_operator_interface

implicit none


!--------------------------------------------------------------------------!
type, extends(linear_solver) :: jacobi_solver                              !
!--------------------------------------------------------------------------!
    real(dp), allocatable :: idiag(:)
contains
    procedure :: init => jacobi_init
    procedure :: linear_solve => jacobi_solve
    procedure :: free => jacobi_free
end type jacobi_solver


contains




!--------------------------------------------------------------------------!
subroutine jacobi_init(solver,A)                                           !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(jacobi_solver), intent(inout) :: solver
    class(linear_operator), intent(in)  :: A
    ! local variables
    integer :: i

    solver%nn = A%nrow

    allocate(solver%idiag(solver%nn))

    do i=1,A%nrow
        solver%idiag(i) = 1.0_dp/A%get_value(i,i)
    enddo

end subroutine jacobi_init



!--------------------------------------------------------------------------!
subroutine jacobi_solve(solver,A,x,b)                                      !
!--------------------------------------------------------------------------!
    class(jacobi_solver), intent(inout) :: solver
    class(linear_operator), intent(in)  :: A
    real(dp), intent(inout)             :: x(:)
    real(dp), intent(in)                :: b(:)

    associate(idiag => solver%idiag)

    x = idiag*b

    end associate

end subroutine jacobi_solve



!--------------------------------------------------------------------------!
subroutine jacobi_free(solver)                                             !
!--------------------------------------------------------------------------!
    class(jacobi_solver), intent(inout) :: solver

    solver%nn = 0

    deallocate(solver%idiag)

end subroutine jacobi_free





end module jacobi_solvers
