! Copyright (C) 2014 Santiago Badia, Alberto F. Martín and Javier Principe
!
! This file is part of FEMPAR (Finite Element Multiphysics PARallel library)
!
! FEMPAR is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! FEMPAR is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with FEMPAR. If not, see <http://www.gnu.org/licenses/>.
!
! Additional permission under GNU GPL version 3 section 7
!
! If you modify this Program, or any covered work, by linking or combining it 
! with the Intel Math Kernel Library and/or the Watson Sparse Matrix Package 
! and/or the HSL Mathematical Software Library (or a modified version of them), 
! containing parts covered by the terms of their respective licenses, the
! licensors of this Program grant you additional permission to convey the 
! resulting work. 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module par_scalar_matrix_names
  ! Serial modules
  use types_names
  use memor_names
  use serial_scalar_matrix_names
  use stdio_names
#ifdef memcheck
  use iso_c_binding
#endif

  ! Parallel modules
  use par_environment_names
  use par_context_names
  use par_scalar_array_names
  use psb_penv_mod_names
  use dof_distribution_names

  ! Abstract types
  use vector_names
  use operator_names
  use matrix_names

  implicit none
# include "debug.i90"

  private

  type, extends(matrix_t) :: par_scalar_matrix_t
     ! Data structure which stores the local part 
     ! of the matrix mapped to the current processor.
     ! This is required for both eb and vb data 
     ! distributions
     type( serial_scalar_matrix_t )       :: f_matrix
     
     type(dof_distribution_t), pointer :: &
        dof_dist => NULL()            ! Associated (ROW) dof_distribution
     
     type(dof_distribution_t), pointer :: &
        dof_dist_cols => NULL()       ! Associated (COL) dof_distribution

     type(par_environment_t), pointer :: &
          p_env => NULL()
   contains
     generic  :: create   => par_scalar_matrix_create_square, &
	                           par_scalar_matrix_create_rectangular
	 procedure, private :: par_scalar_matrix_create_square
	 procedure, private :: par_scalar_matrix_create_rectangular
	 
	 procedure  :: allocate => par_scalar_matrix_allocate
     procedure  :: print_matrix_market => par_scalar_matrix_print_matrix_market						 
	 procedure  :: init      => par_scalar_matrix_init
     procedure  :: apply     => par_scalar_matrix_apply
     procedure  :: apply_fun => par_scalar_matrix_apply_fun
	 procedure  :: free_in_stages => par_scalar_matrix_free_in_stages
  end type par_scalar_matrix_t

  ! Types
  public :: par_scalar_matrix_t


!***********************************************************************
! Allocatable arrays of type(par_scalar_matrix_t)
!***********************************************************************
# define var_attr allocatable, target
# define point(a,b) call move_alloc(a,b)
# define generic_status_test             allocated
# define generic_memalloc_interface      memalloc
# define generic_memrealloc_interface    memrealloc
# define generic_memfree_interface       memfree
# define generic_memmovealloc_interface  memmovealloc

# define var_type type(par_scalar_matrix_t)
# define var_size 80
# define bound_kind ip
# include "mem_header.i90"

  public :: memalloc,  memrealloc,  memfree, memmovealloc

contains

# include "mem_body.i90"
  
  !=============================================================================
  subroutine par_scalar_matrix_create_square(this,symmetric_storage,is_symmetric,sign,dof_dist,p_env)
    implicit none
	class(par_scalar_matrix_t)          ,intent(out) :: this
	logical                             ,intent(in)  :: symmetric_storage
    logical                             ,intent(in)  :: is_symmetric
	integer(ip)                         ,intent(in)  :: sign
    type(dof_distribution_t), target    ,intent(in)  :: dof_dist
    type(par_environment_t) , target    ,intent(in)  :: p_env

    call this%f_matrix%create(symmetric_storage,is_symmetric,sign)
    this%dof_dist      => dof_dist 
    this%dof_dist_cols => dof_dist
    this%p_env => p_env
  end subroutine par_scalar_matrix_create_square
  
  !=============================================================================
  subroutine par_scalar_matrix_create_rectangular(this,dof_dist,dof_dist_cols,p_env)
    implicit none
	class(par_scalar_matrix_t)          ,intent(out) :: this
    type(dof_distribution_t), target    ,intent(in)  :: dof_dist
	type(dof_distribution_t), target    ,intent(in)  :: dof_dist_cols
    type(par_environment_t) , target    ,intent(in)  :: p_env

    call this%f_matrix%create()
    this%dof_dist => dof_dist 
    this%dof_dist_cols => dof_dist_cols
    this%p_env => p_env
  end subroutine par_scalar_matrix_create_rectangular
  
  subroutine par_scalar_matrix_allocate(this)
    implicit none
    class(par_scalar_matrix_t), intent(inout) :: this

    if(this%p_env%p_context%iam>=0) then
       call this%f_matrix%allocate()
    end if
  end subroutine par_scalar_matrix_allocate

  !=============================================================================
  subroutine par_scalar_matrix_free_in_stages(this, action)
    implicit none
    class(par_scalar_matrix_t), intent(inout) :: this
    integer(ip)               , intent(in)    :: action

    ! The routine requires the partition/context info
    assert ( associated(this%dof_dist) )
    assert ( associated(this%p_env%p_context) )
    assert ( this%p_env%p_context%created .eqv. .true.)
    assert ( action == free_clean .or. action == free_struct .or. action == free_values )

    if(this%p_env%p_context%iam<0) return

    if ( action == free_clean ) then
       nullify ( this%dof_dist )
       nullify ( this%dof_dist_cols )
       nullify ( this%p_env )
	   call this%f_matrix%free_in_stages(action)
    else if ( action == free_struct ) then
	   call this%f_matrix%free_in_stages(action)
	else if ( action == free_values ) then
	   call this%f_matrix%free_in_stages(action)
    end if
	
  end subroutine par_scalar_matrix_free_in_stages
  

  subroutine par_scalar_matrix_print_matrix_market ( this, dir_path, prefix )
    implicit none
	class(par_scalar_matrix_t), intent(in) :: this
    character (*)            , intent(in) :: dir_path
    character (*)            , intent(in) :: prefix
    integer         :: iam, num_procs, lunou
    integer(ip)     :: j, ndigs_iam, ndigs_num_procs, id_map
    character(256)  :: name 
    character(256)  :: zeros
    character(256)  :: part_id

    assert ( associated(this%p_env%p_context) )
    assert ( this%p_env%p_context%created .eqv. .true.)
    if(this%p_env%p_context%iam<0) return


    name = trim(prefix) // '.par_matrix' // '.mtx'

    ! Get context info
    call par_context_info ( this%p_env%p_context, iam, num_procs )

    ! Form the file_path of the partition object to be read
    iam = iam + 1 ! Partition identifers start from 1 !!
     
    ndigs_num_procs = count_digits_par_matrix (num_procs)
    zeros = ' '   
    ndigs_iam = count_digits_par_matrix ( iam )
   
    ! write(*,*) ndgs_num_procs, ndigs_iam DBG
    
    do j=1,  ndigs_num_procs - ndigs_iam
       zeros (j:j) = '0'
    end do
    part_id = ch(iam)

    ! Read partition data from path_file file
    lunou =  io_open (trim(dir_path) // '/' // trim(name) // '.' // trim(zeros) // trim(part_id), 'write')
	
    call this%f_matrix%print_matrix_market(lunou)

    call io_close (lunou)

  end subroutine par_scalar_matrix_print_matrix_market

  function count_digits_par_matrix ( i )
    implicit none
    ! Parameters
    integer(ip), intent(in) :: i 
    integer(ip)             :: count_digits_par_matrix
    ! Locals   
    integer(ip)             :: x 
    x = i 
    if (x < 0) x = -x;
    count_digits_par_matrix = 1;
    x = x/10;
    do while( x > 0)
       count_digits_par_matrix = count_digits_par_matrix + 1
       x = x/10;
    end do
  end function count_digits_par_matrix

  subroutine par_scalar_matrix_init (p_matrix, alpha)
    implicit none
    ! Parameters 
    class(par_scalar_matrix_t), intent(inout) :: p_matrix
	real(rp)                  , intent(in)    :: alpha    

    ! p_env%p_context is required within this subroutine
    assert ( associated(p_matrix%p_env%p_context) )
    assert ( p_matrix%p_env%p_context%created .eqv. .true.)

    if(p_matrix%p_env%p_context%iam<0) return

    call p_matrix%f_matrix%init(alpha)
  end subroutine par_scalar_matrix_init

  subroutine par_scalar_matrix_apply_concrete(a,x,y)
    implicit none
    ! Parameters
    type(par_scalar_matrix_t) , intent(in)    :: a
    type(par_scalar_array_t) , intent(in)    :: x
    type(par_scalar_array_t) , intent(inout) :: y
    ! Locals
    !integer(c_int)                   :: ierrc
    real :: aux

    ! This routine requires the partition/context info
    assert ( associated(a%p_env) )
    assert ( associated(a%p_env%p_context) )

    assert ( a%p_env%p_context%created .eqv. .true.)
    if(a%p_env%p_context%iam<0) return

    assert ( associated(x%p_env) )
    assert ( associated(x%p_env%p_context) )

    assert ( associated(y%p_env) )
    assert ( associated(y%p_env%p_context) )
    
    assert (x%state == full_summed) 
    call a%f_matrix%apply(x%f_vector, y%f_vector)
    y%state = part_summed
  end subroutine par_scalar_matrix_apply_concrete

  ! op%apply(x,y) <=> y <- op*x
  ! Implicitly assumes that y is already allocated
  subroutine par_scalar_matrix_apply(op,x,y) 
    implicit none
    class(par_scalar_matrix_t), intent(in)    :: op
    class(vector_t) , intent(in)    :: x
    class(vector_t) , intent(inout) :: y 

    call x%GuardTemp()

    select type(x)
    class is (par_scalar_array_t)
       select type(y)
       class is(par_scalar_array_t)
          call par_scalar_matrix_apply_concrete(op, x, y)
          ! call vector_print(6,y)
       class default
          write(0,'(a)') 'par_scalar_matrix_t%apply: unsupported y class'
          check(1==0)
       end select
    class default
       write(0,'(a)') 'par_scalar_matrix_t%apply: unsupported x class'
       check(1==0)
    end select

    call x%CleanTemp()
  end subroutine par_scalar_matrix_apply

  ! op%apply(x)
  ! Allocates room for (temporary) y
  function par_scalar_matrix_apply_fun(op,x) result(y)
    implicit none
    class(par_scalar_matrix_t), intent(in)  :: op
    class(vector_t) , intent(in)  :: x
    class(vector_t) , allocatable :: y 

    type(par_scalar_array_t), allocatable :: local_y

    select type(x)
    class is (par_scalar_array_t)
       allocate(local_y)
       call local_y%create_and_allocate (op%dof_dist, x%p_env)
       call par_scalar_matrix_apply(op, x, local_y)
       call move_alloc(local_y, y)
       call y%SetTemp()
    class default
       write(0,'(a)') 'par_scalar_matrix_t%apply_fun: unsupported x class'
       check(1==0)
    end select
  end function par_scalar_matrix_apply_fun


end module par_scalar_matrix_names
