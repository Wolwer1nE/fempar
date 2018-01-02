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

module unfitted_triangulations_names
  use types_names
  use field_names
  use reference_fe_names
  use fpl
  use environment_names
  use list_types_names
  use par_scalar_array_names
  use vector_names
  use serial_scalar_array_names
  use triangulation_names
  use level_set_functions_gallery_names
  use base_sparse_matrix_names
  use dof_import_names
  use p4est_triangulation_names
  
  
  use fe_space_names
  use conditions_names
  use block_layout_names
  use function_names
  
  implicit none
# include "debug.i90"
  private

  ! Include the look-up tables 
# include "mc_tables_qua4.i90"
# include "mc_tables_hex8.i90"
  
  type, extends(bst_cell_iterator_t) :: unfitted_cell_iterator_t
    private
    class(marching_cubes_t), pointer :: marching_cubes => NULL()
  contains

    ! Creation / deletion methods
    procedure :: create => unfitted_cell_iterator_create
    procedure :: free   => unfitted_cell_iterator_free
    
    ! Updater: to be called each time the lid changes
    procedure :: update_sub_triangulation    => unfitted_cell_iterator_update_sub_triangulation

    ! Getters related with the subcells
    procedure :: get_num_subcells      => unfitted_cell_iterator_get_num_subcells
    procedure :: get_num_subcell_nodes => unfitted_cell_iterator_get_num_subcell_nodes
    procedure :: get_phys_coords_of_subcell  => unfitted_cell_iterator_get_phys_coords_of_subcell
    procedure :: get_ref_coords_of_subcell   => unfitted_cell_iterator_get_ref_coords_of_subcell
    
    ! Getters related with the subfacets
    procedure :: get_num_subfacets      => unfitted_cell_iterator_get_num_subfacets
    procedure :: get_num_subfacet_nodes => unfitted_cell_iterator_get_num_subfacet_nodes
    procedure :: get_phys_coords_of_subfacet  => unfitted_cell_iterator_get_phys_coords_of_subfacet
    procedure :: get_ref_coords_of_subfacet   => unfitted_cell_iterator_get_ref_coords_of_subfacet
    
    ! Checkers
    procedure :: is_cut      => unfitted_cell_iterator_is_cut
    procedure :: is_interior => unfitted_cell_iterator_is_interior
    procedure :: is_exterior => unfitted_cell_iterator_is_exterior
    procedure :: is_interior_subcell => unfitted_cell_iterator_is_interior_subcell
    procedure :: is_exterior_subcell => unfitted_cell_iterator_is_exterior_subcell

    ! Private TBPs
    procedure, non_overridable, private :: get_num_subnodes         => unfitted_cell_iterator_get_num_subnodes
    procedure, non_overridable, private :: subcell_has_been_reoriented    => unfitted_cell_iterator_subcell_has_been_reoriented
    procedure, non_overridable, private :: subfacet_touches_interior_reoriented_subcell => unfitted_cell_iterator_subfacet_touches_reoriented_subcell
    end type unfitted_cell_iterator_t

  type, extends(bst_vef_iterator_t) :: unfitted_vef_iterator_t
    private
    class(marching_cubes_t), pointer :: marching_cubes => NULL()
    class(cell_iterator_t), allocatable :: unfitted_cell
    integer(ip) :: facet_lid
  contains

    ! Creation / deletion methods
    procedure :: create => unfitted_vef_iterator_create
    procedure :: free   => unfitted_vef_iterator_free

    ! TBPs that change the gid
    procedure :: first        => unfitted_vef_iterator_first
    procedure :: next         => unfitted_vef_iterator_next
    procedure :: set_gid      => unfitted_vef_iterator_set_gid
    
    ! Updater: to be called each time the lid changes
    procedure :: update_sub_triangulation    => unfitted_vef_iterator_update_sub_triangulation
    
    ! Getters related with the subvefs
    procedure :: get_num_subvefs      => unfitted_vef_iterator_get_num_subvefs
    procedure :: get_num_subvef_nodes => unfitted_vef_iterator_get_num_subvef_nodes
    procedure :: get_phys_coords_of_subvef  => unfitted_vef_iterator_get_phys_coords_of_subvef
    procedure :: get_ref_coords_of_subvef   => unfitted_vef_iterator_get_ref_coords_of_subvef
    
    ! Checkers
    procedure :: is_cut      => unfitted_vef_iterator_is_cut
    procedure :: is_interior => unfitted_vef_iterator_is_interior
    procedure :: is_exterior => unfitted_vef_iterator_is_exterior
    procedure :: is_interior_subvef => unfitted_vef_iterator_is_interior_subvef
    procedure :: is_exterior_subvef => unfitted_vef_iterator_is_exterior_subvef

    ! Private TBP's
    procedure, private, non_overridable :: update_unfitted_cell  => unfitted_vef_iterator_update_unfitted_cell

  end type unfitted_vef_iterator_t

  type, extends(unfitted_cell_iterator_t) :: unfitted_p4est_cell_iterator_t
    private
    type(p4est_cell_iterator_t) :: p4est_cell
  contains

    ! TBPs that change the gid
    procedure                            :: create                  => unfitted_p4est_cell_iterator_create
    procedure                            :: free                    => unfitted_p4est_cell_iterator_free
    procedure                            :: next                    => unfitted_p4est_cell_iterator_next
    procedure                            :: first                   => unfitted_p4est_cell_iterator_first
    procedure                            :: set_gid                 => unfitted_p4est_cell_iterator_set_gid

    ! TBPS that only relay on this::p4est_cell
    procedure                            :: get_reference_fe        => unfitted_p4est_cell_iterator_get_reference_fe
    procedure                            :: get_reference_fe_id     => unfitted_p4est_cell_iterator_get_reference_fe_id
    procedure                            :: get_set_id              => unfitted_p4est_cell_iterator_get_set_id
    procedure                            :: set_set_id              => unfitted_p4est_cell_iterator_set_set_id
    procedure                            :: get_level               => unfitted_p4est_cell_iterator_get_level
    procedure                            :: get_num_vefs            => unfitted_p4est_cell_iterator_get_num_vefs
    procedure                            :: get_num_nodes           => unfitted_p4est_cell_iterator_get_num_nodes
    procedure                            :: get_nodes_coordinates   => unfitted_p4est_cell_iterator_get_nodes_coordinates
    procedure                            :: get_ggid                => unfitted_p4est_cell_iterator_get_ggid
    procedure                            :: get_my_part             => unfitted_p4est_cell_iterator_get_my_part
    procedure                            :: get_vef_gid             => unfitted_p4est_cell_iterator_get_vef_gid
    procedure                            :: get_vefs_gid            => unfitted_p4est_cell_iterator_get_vefs_gid
    procedure                            :: get_vef_ggid            => unfitted_p4est_cell_iterator_get_vef_ggid
    procedure                            :: get_vef_lid_from_gid    => unfitted_p4est_cell_iterator_get_vef_lid_from_gid
    procedure                            :: get_vef_lid_from_ggid   => unfitted_p4est_cell_iterator_get_vef_lid_from_ggid
    procedure                            :: get_vef                 => unfitted_p4est_cell_iterator_get_vef
    procedure                            :: is_local                => unfitted_p4est_cell_iterator_is_local
    procedure                            :: is_ghost                => unfitted_p4est_cell_iterator_is_ghost
    procedure                            :: is_ancestor             => unfitted_p4est_cell_iterator_is_ancestor
    procedure                            :: set_for_coarsening      => unfitted_p4est_cell_iterator_set_for_coarsening
    procedure                            :: set_for_refinement      => unfitted_p4est_cell_iterator_set_for_refinement
    procedure                            :: set_for_do_nothing      => unfitted_p4est_cell_iterator_set_for_do_nothing
    procedure                            :: get_transformation_flag => unfitted_p4est_cell_iterator_get_transformation_flag
    procedure                            :: get_permutation_index   => unfitted_p4est_cell_iterator_get_permutation_index

  end type unfitted_p4est_cell_iterator_t

  ! We need this to create a par fe space in marching_cubes_t to hold a discrete levelset function
  type, extends(standard_l1_coarse_fe_handler_t) :: mc_dummy_coarse_fe_handler_t
    contains
      procedure :: get_num_coarse_dofs       => mc_dummy_coarse_fe_handler_get_num_coarse_dofs
      procedure :: setup_constraint_matrix   => mc_dummy_coarse_fe_handler_setup_constraint_matrix
      procedure :: setup_weighting_operator  => mc_dummy_coarse_fe_handler_setup_weighting_operator
  end type mc_dummy_coarse_fe_handler_t

  ! We need this to create a fe space in marching_cubes_t to hold a discrete levelset function
  type, extends(conditions_t) :: mc_dummy_conditions_t
    contains
      procedure :: get_num_components  => mc_dummy_conditions_get_num_components
      procedure :: get_components_code    => mc_dummy_conditions_get_components_code
      procedure :: get_function           => mc_dummy_conditions_get_function
  end type mc_dummy_conditions_t

  type :: marching_cubes_t
    private

    ! The underlying triangulation
    class(triangulation_t), pointer :: triangulation => null()

    ! The level set funciton
    class(level_set_function_t), pointer :: level_set_function => null()

    ! The discrete version of the level-set function
    type(fe_function_t) :: fe_levelset

    ! The fe space associated with the discrete version of the levelset function
    class(serial_fe_space_t), allocatable :: fe_space
    type(block_layout_t)                  :: block_layout

    ! Auxiliary dummy things to create the fe space for the levelset
    type(p_reference_fe_t), allocatable :: reference_fes(:) 
    type(mc_dummy_coarse_fe_handler_t)  :: dummy_coarse_handler
    type(mc_dummy_conditions_t)         :: dummy_conditions
    type(p_l1_coarse_fe_handler_t), allocatable  :: dummy_coarse_handlers(:)

    ! Look up-tables (precomputed off-line, for each cell type)
    integer(ip)                :: mc_table_num_cases
    integer(ip)                :: mc_table_num_facets
    integer(ip)                :: mc_table_max_num_sub_cells
    integer(ip)                :: mc_table_max_num_unfitted_sub_facets
    integer(ip)                :: mc_table_max_num_fitted_sub_facets_in_facet
    integer(ip)                :: mc_table_max_num_cut_edges
    integer(ip)                :: mc_table_num_nodes_in_sub_cell
    integer(ip)                :: mc_table_num_nodes_in_sub_facet
    integer(ip),   allocatable :: mc_table_num_sub_cells_x_case(:)
    integer(ip),   allocatable :: mc_table_num_unfitted_sub_facets_x_case(:)
    integer(ip),   allocatable :: mc_table_num_fitted_sub_facets_x_case_and_facet(:,:)
    integer(ip),   allocatable :: mc_table_num_cut_edges_x_case(:)
    integer(ip),   allocatable :: mc_table_sub_cells_status_x_case(:,:)
    integer(ip),   allocatable :: mc_table_facet_status_x_case_and_facet(:,:)
    integer(ip),   allocatable :: mc_table_fitted_sub_facets_status_x_case_and_facet(:,:,:)
    integer(ip),   allocatable :: mc_table_sub_cells_node_ids_x_case(:,:,:)
    integer(ip),   allocatable :: mc_table_unfitted_sub_facets_node_ids_x_case(:,:,:)
    integer(ip),   allocatable :: mc_table_fitted_sub_facets_node_ids_x_case_and_facet(:,:,:,:)
    logical :: mc_tables_init = .false.

    ! Info related to cut cells on this triangulation (this is computed at runtime)
    integer(ip),   allocatable :: mc_case_x_cell(:)
    integer(ip),   allocatable :: mc_ptr_to_intersections(:)
    type(point_t), allocatable :: mc_intersection_points(:)
    logical :: mc_runtime_init = .false.

    ! Info related to the sub-tessellation
    ! When located on a cell, and the sub-triangulation is updated,
    ! these memeber variables contain info about the current sub-tessalation
    integer(ip),        allocatable :: sub_cells_node_ids(:,:)
    integer(ip),        allocatable :: unfitted_sub_facets_node_ids(:,:)
    integer(ip),        allocatable :: fitted_sub_facets_node_ids_x_facet(:,:,:)
    type(point_t),      allocatable :: subnodes_ref_coords(:)
    logical,            allocatable :: sub_cell_has_been_reoriented(:)
    
    ! Auxiliary work data
    type(quadrature_t), allocatable :: sub_nodes_nodal_quadratures(:)
    type(cell_map_t),   allocatable :: sub_nodes_cell_maps(:)

  contains

    ! Creation / deletion methods
    procedure                  :: create                        => marching_cubes_create
    procedure                  :: free                          => marching_cubes_free

    ! Getters
    procedure, non_overridable :: get_num_cut_cells             => marching_cubes_get_num_cut_cells
    procedure, non_overridable :: get_num_interior_cells        => marching_cubes_get_num_interior_cells
    procedure, non_overridable :: get_num_exterior_cells        => marching_cubes_get_num_exterior_cells
    procedure, non_overridable :: get_max_num_subcells_in_cell  => marching_cubes_get_max_num_subcells_in_cell
    procedure, non_overridable :: get_max_num_nodes_in_subcell  => marching_cubes_get_max_num_nodes_in_subcell
    procedure, non_overridable :: get_total_num_subcells     => marching_cubes_get_total_num_subcells
    procedure, non_overridable :: get_max_num_subfacets_in_cell  => marching_cubes_get_max_num_subfacets_in_cell
    procedure, non_overridable :: get_max_num_nodes_in_subfacet  => marching_cubes_get_max_num_nodes_in_subfacet
    procedure, non_overridable :: get_total_num_subfacets     => marching_cubes_get_total_num_subfacets
    procedure, non_overridable :: get_total_num_fitted_sub_facets  => marching_cubes_get_total_num_fitted_sub_facets
    procedure, non_overridable :: get_max_num_subnodes_in_cell  => marching_cubes_get_max_num_subnodes_in_cell
    procedure, non_overridable :: get_num_dims            => marching_cubes_get_num_dims
    procedure, non_overridable :: get_max_num_shape_functions            => marching_cubes_get_max_num_shape_functions
    procedure, non_overridable :: get_num_facets => marching_cubes_get_num_facets
    procedure, non_overridable :: get_num_sub_cells => marching_cubes_get_num_sub_cells
    procedure, non_overridable :: get_num_unfitted_sub_facets => marching_cubes_get_num_unfitted_sub_facets
    procedure, non_overridable :: get_num_fitted_sub_facets => marching_cubes_get_num_fitted_sub_facets
    
    ! Getters related with the mc algorithm
    procedure, non_overridable :: get_num_mc_cases              => marching_cubes_get_num_mc_cases
    procedure, non_overridable :: get_num_subcells_mc_case      => marching_cubes_get_num_subcells_mc_case
    procedure, non_overridable :: get_num_subfacets_mc_case      => marching_cubes_get_num_subfacets_mc_case
    
    ! Printers
    procedure :: print                     => marching_cubes_print
    
    ! Private TBP
    procedure, non_overridable, private :: fulfills_assumptions           => marching_cubes_fulfills_assumptions
    procedure, non_overridable, private :: mc_tables_create               => marching_cubes_mc_tables_create
    procedure, non_overridable, private :: mc_tables_free                 => marching_cubes_mc_tables_free
    procedure, non_overridable, private :: discrete_levelset_create       => marching_cubes_discrete_levelset_create
    procedure, non_overridable, private :: discrete_levelset_free         => marching_cubes_discrete_levelset_free
    procedure, non_overridable, private :: discrete_levelset_fix          => marching_cubes_discrete_levelset_fix
    procedure, non_overridable, private :: discrete_levelset_comm         => marching_cubes_discrete_levelset_comm
    procedure, non_overridable, private :: mc_runtime_info_create         => marching_cubes_mc_runtime_info_create
    procedure, non_overridable, private :: mc_runtime_info_free           => marching_cubes_mc_runtime_info_free
    procedure, non_overridable, private :: subnodes_data_create           => marching_cubes_subnodes_data_create
    procedure, non_overridable, private :: subnodes_data_free             => marching_cubes_subnodes_data_free
  end type marching_cubes_t

  type, extends(serial_triangulation_t) :: serial_unfitted_triangulation_t
    private
      type(marching_cubes_t) :: marching_cubes
    contains
      ! Creation / deletion methods
      generic             :: create                       => sut_create
      procedure           :: free                         => sut_free
      procedure,  private :: serial_triangulation_create  => sut_serial_triangulation_create
      procedure,  private :: sut_create

      ! Generate iterator by overloading the procedure of the father
      procedure :: create_cell_iterator => sut_create_cell_iterator
      procedure :: create_vef_iterator => sut_create_vef_iterator

      ! Getters
      procedure, non_overridable :: get_marching_cubes            => sut_get_marching_cubes
      procedure, non_overridable :: get_num_cut_cells             => sut_get_num_cut_cells
      procedure, non_overridable :: get_num_interior_cells        => sut_get_num_interior_cells
      procedure, non_overridable :: get_num_exterior_cells        => sut_get_num_exterior_cells
      procedure, non_overridable :: get_max_num_subcells_in_cell  => sut_get_max_num_subcells_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subcell  => sut_get_max_num_nodes_in_subcell
      procedure, non_overridable :: get_total_num_subcells     => sut_get_total_num_subcells
      procedure, non_overridable :: get_max_num_subfacets_in_cell  => sut_get_max_num_subfacets_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subfacet  => sut_get_max_num_nodes_in_subfacet
      procedure, non_overridable :: get_total_num_subfacets     => sut_get_total_num_subfacets
      procedure, non_overridable :: get_total_num_fitted_sub_facets  => sut_get_total_num_fitted_sub_facets
      procedure, non_overridable :: get_max_num_subnodes_in_cell  => sut_get_max_num_subnodes_in_cell

      ! TODO this getters should be removed in the future
      ! Now the fe space uses them.
      ! The goal is that the fe space does not assume that the tesselation algorithm is the mc algorithm
      procedure, non_overridable :: get_num_mc_cases              => sut_get_num_mc_cases
      procedure, non_overridable :: get_num_subcells_mc_case      => sut_get_num_subcells_mc_case
      procedure, non_overridable :: get_num_subfacets_mc_case      => sut_get_num_subfacets_mc_case

      ! Printers
      procedure :: print                     => sut_print

  end type serial_unfitted_triangulation_t

  type, extends(p4est_serial_triangulation_t) :: unfitted_p4est_serial_triangulation_t
    private
      type(marching_cubes_t) :: marching_cubes
    contains

      ! Creation / deletion methods
      generic             :: create                       => upst_create
      procedure           :: free                         => upst_free
      procedure           :: update_cut_cells             => upst_update_cut_cells
      procedure           :: serial_triangulation_create  => upst_serial_triangulation_create
      procedure,  private :: upst_create

      ! Generate iterator by overloading the procedure of the father
      procedure :: create_cell_iterator => upst_create_cell_iterator
      !procedure :: create_vef_iterator  => upst_create_vef_iterator

      ! Getters
      procedure, non_overridable :: get_marching_cubes            => upst_get_marching_cubes
      procedure, non_overridable :: get_num_cut_cells             => upst_get_num_cut_cells
      procedure, non_overridable :: get_num_interior_cells        => upst_get_num_interior_cells
      procedure, non_overridable :: get_num_exterior_cells        => upst_get_num_exterior_cells
      procedure, non_overridable :: get_max_num_subcells_in_cell  => upst_get_max_num_subcells_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subcell  => upst_get_max_num_nodes_in_subcell
      procedure, non_overridable :: get_total_num_subcells     => upst_get_total_num_subcells
      procedure, non_overridable :: get_max_num_subfacets_in_cell  => upst_get_max_num_subfacets_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subfacet  => upst_get_max_num_nodes_in_subfacet
      procedure, non_overridable :: get_total_num_subfacets     => upst_get_total_num_subfacets
      procedure, non_overridable :: get_max_num_subnodes_in_cell  => upst_get_max_num_subnodes_in_cell

      ! TODO this getters should be removed in the future
      ! Now the fe space uses them.
      ! The goal is that the fe space does not assume that the tesselation algorithm is the mc algorithm
      procedure, non_overridable :: get_num_mc_cases              => upst_get_num_mc_cases
      procedure, non_overridable :: get_num_subcells_mc_case      => upst_get_num_subcells_mc_case
      procedure, non_overridable :: get_num_subfacets_mc_case      => upst_get_num_subfacets_mc_case

      ! Printers
      procedure :: print                     => upst_print

  end type unfitted_p4est_serial_triangulation_t

  type, extends(par_triangulation_t) :: par_unfitted_triangulation_t
    private
      type(marching_cubes_t) :: marching_cubes
    contains

      ! Creation / deletion methods
      generic             :: create                       => put_create
      procedure           :: free                         => put_free
      procedure,  private :: par_triangulation_create     => put_par_triangulation_create
      procedure,  private :: put_create

      ! Generate iterator by overloading the procedure of the father
      procedure :: create_cell_iterator          => put_create_cell_iterator
      !procedure :: create_vef_iterator           => put_create_vef_iterator

      ! Getters
      procedure, non_overridable :: get_marching_cubes            => put_get_marching_cubes
      procedure, non_overridable :: get_num_cut_cells             => put_get_num_cut_cells
      procedure, non_overridable :: get_num_interior_cells        => put_get_num_interior_cells
      procedure, non_overridable :: get_num_exterior_cells        => put_get_num_exterior_cells
      procedure, non_overridable :: get_max_num_subcells_in_cell  => put_get_max_num_subcells_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subcell  => put_get_max_num_nodes_in_subcell
      procedure, non_overridable :: get_total_num_subcells     => put_get_total_num_subcells
      procedure, non_overridable :: get_max_num_subfacets_in_cell  => put_get_max_num_subfacets_in_cell
      procedure, non_overridable :: get_max_num_nodes_in_subfacet  => put_get_max_num_nodes_in_subfacet
      procedure, non_overridable :: get_total_num_subfacets     => put_get_total_num_subfacets
      procedure, non_overridable :: get_max_num_subnodes_in_cell  => put_get_max_num_subnodes_in_cell

      ! TODO this getters should be removed in the future
      ! Now the fe space uses them.
      ! The goal is that the fe space does not assume that the tesselation algorithm is the mc algorithm
      procedure, non_overridable :: get_num_mc_cases              => put_get_num_mc_cases
      procedure, non_overridable :: get_num_subcells_mc_case      => put_get_num_subcells_mc_case
      procedure, non_overridable :: get_num_subfacets_mc_case      => put_get_num_subfacets_mc_case

      ! Printers
      procedure :: print                     => put_print

  end type par_unfitted_triangulation_t

  ! Derived types
  public :: unfitted_cell_iterator_t
  public :: unfitted_p4est_cell_iterator_t
  public :: serial_unfitted_triangulation_t
  public :: unfitted_p4est_serial_triangulation_t
  public :: par_unfitted_triangulation_t

contains

#include "sbm_unfitted_cell_iterator.i90"
#include "sbm_unfitted_vef_iterator.i90"
#include "sbm_unfitted_p4est_cell_iterator.i90"
#include "sbm_marching_cubes.i90"
#include "sbm_serial_unfitted_triangulation.i90"
#include "sbm_unfitted_p4est_serial_triangulation.i90"
#include "sbm_par_unfitted_triangulation.i90"

end module unfitted_triangulations_names

